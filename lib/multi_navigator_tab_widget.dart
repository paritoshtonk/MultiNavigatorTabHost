library multi_navigator_tab_widget;

import 'package:flutter/widgets.dart';

typedef CreateTabCallback = List<Widget> Function(
    BuildContext context, int count, int selected);
typedef PageRouteCallback = Route<dynamic> Function(
    RouteSettings setting, int index);

class MultiNavigatorTabHost extends StatefulWidget {
  MultiNavigatorTabHost(
      {Key key,
      @required this.onCreateTabs,
      @required this.pageRouteCallback,
      this.initialTabCount,
      this.tabBarBackgroundColor,
      this.bottomTabs,
      this.alignment})
      : super(key: key) {
    if (initialTabCount != null && initialTabCount < 1)
      throw FormatException("initialTabCount needs to be atleast 1",
          initialTabCount, initialTabCount);
  }

  final CreateTabCallback onCreateTabs;
  final PageRouteCallback pageRouteCallback;
  final int initialTabCount;
  final bool bottomTabs;
  final Alignment alignment;
  final Color tabBarBackgroundColor;

  @override
  MultiNavigatorTabHostState createState() => MultiNavigatorTabHostState();
}

class MultiNavigatorTabHostState extends State<MultiNavigatorTabHost> {
  List<GlobalKey<NavigatorState>> _navigatorStateKeys = [];
  int _currentTab = 0;

  int get currentTab => _currentTab;
  int get tabCount => _navigatorStateKeys.length;
  static MultiNavigatorTabHostState of(BuildContext context) {
    return context.findAncestorStateOfType<MultiNavigatorTabHostState>();
  }

  @override
  void initState() {
    super.initState();
    int count = widget.initialTabCount;
    if (count == null) count = 1;
    for (int i = 0; i < count; i++) _navigatorStateKeys.add(new GlobalKey());
  }

  void addTab({bool focusOnNewTab}) {
    setState(() {
      _navigatorStateKeys.add(GlobalKey());
      if (focusOnNewTab != null && focusOnNewTab)
        _currentTab = _navigatorStateKeys.length - 1;
    });
  }

  void addTabAt(index, {bool focusOnNewTab}) {
    if (index < 0 || index > _navigatorStateKeys.length) {
      throw FormatException("Index is out of bound");
    }
    setState(() {
      if (index == _navigatorStateKeys.length) {
        _navigatorStateKeys.add(GlobalKey());
        if (focusOnNewTab != null && focusOnNewTab)
          _currentTab = _navigatorStateKeys.length - 1;
      } else {
        _navigatorStateKeys.insert(index, GlobalKey());
        if (focusOnNewTab != null && focusOnNewTab && index <= currentTab)
          _currentTab++;
      }
    });
  }

  void removeTab(int index) {
    if (_navigatorStateKeys.length == 1)
      throw Exception(
          "Underflow: Cant remove the only tab. There needs to be atleast one tab.");
    if (index < 0 || index >= _navigatorStateKeys.length)
      throw FormatException("Index is out of bound");
    setState(() {
      if (index == _navigatorStateKeys.length - 1) _currentTab -= 1;
      _navigatorStateKeys.removeAt(index);
    });
  }

  void setSelected(int index) {
    if (index < 0 || index >= _navigatorStateKeys.length) {
      throw FormatException("Index is out of bound");
    }
    setState(() {
      _currentTab = index;
    });
  }

  List<Widget> _getTabs(BuildContext context) {
    var tabs =
        widget.onCreateTabs(context, _navigatorStateKeys.length, currentTab);
    if (tabs.length != _navigatorStateKeys.length) {
      throw Exception("Tab Count is not equal to Navigator counts");
    }
    return tabs;
  }

  Widget _getTabScrollWidget(BuildContext iContext) {
    return Container(
      color: widget.tabBarBackgroundColor == null
          ? Color(0)
          : widget.tabBarBackgroundColor,
      child: Align(
        alignment: widget.alignment ?? Alignment.center,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _getTabs(iContext),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_navigatorStateKeys[currentTab].currentState.canPop())
          return !await _navigatorStateKeys[currentTab].currentState.maybePop();
        else
          return false;
      },
      child: Builder(
        builder: (BuildContext iContext) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (widget.bottomTabs == null || !widget.bottomTabs)
                _getTabScrollWidget(iContext),
              Expanded(
                child: IndexedStack(
                  index: currentTab,
                  children: _getNavigatorsWidgets(),
                ),
              ),
              if (widget.bottomTabs != null && widget.bottomTabs)
                _getTabScrollWidget(iContext),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _getNavigatorsWidgets() {
    List<Widget> navigators = [];
    for (int i = 0; i < _navigatorStateKeys.length; i++)
      navigators.add(
        Navigator(
          key: _navigatorStateKeys[i],
          onGenerateRoute: (routeSettings) {
            return widget.pageRouteCallback(routeSettings, i);
          },
        ),
      );
    return navigators;
  }
}
