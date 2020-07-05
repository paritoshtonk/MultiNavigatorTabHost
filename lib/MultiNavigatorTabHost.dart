library multi_navigator_tab_widget;

import 'package:flutter/widgets.dart';

typedef CreateTabCallback = Widget Function(
    BuildContext context, int index, int count, bool selected, String title);
typedef PageRouteCallback = Route<dynamic> Function(
    RouteSettings setting, int index);
typedef OnUnknownRoute = Route<dynamic> Function(RouteSettings settings);

class MultiNavigatorTabHost extends StatefulWidget {
  MultiNavigatorTabHost(
      {Key key,
      @required this.onCreateTab,
      @required this.pageRouteCallback,
      @required this.initialTabNames,
      @required this.initialTabCount,
      this.onUnknownRoute,
      this.tabBarBackgroundColor = const Color(0),
      this.bottomTabs = false,
      this.alignment = Alignment.center,
      this.initialRoute = "/"})
      : super(key: key) {
    if (initialTabCount != null && initialTabCount < 1)
      throw FormatException("initialTabCount needs to be atleast 1",
          initialTabCount, initialTabCount);
    if (initialTabCount != initialTabNames.length)
      throw FormatException("There needs to be initialTabCount intialTabNames");
  }
  final OnUnknownRoute onUnknownRoute;
  final CreateTabCallback onCreateTab;
  final PageRouteCallback pageRouteCallback;
  final int initialTabCount;
  final bool bottomTabs;
  final Alignment alignment;
  final Color tabBarBackgroundColor;
  final List<String> initialTabNames;
  final String initialRoute;

  @override
  MultiNavigatorTabHostState createState() => MultiNavigatorTabHostState();

  static MultiNavigatorTabHostState of(BuildContext context) {
    return context.findAncestorStateOfType<MultiNavigatorTabHostState>();
  }
}

class MultiNavigatorTabHostState extends State<MultiNavigatorTabHost> {
  List<GlobalKey<NavigatorState>> _navigatorStateKeys = [];
  int _currentTab = 0;
  List<String> _titles = [];
  Map<int, RouteSettings> initialRouteSettingsMap = {};
  Map<int, Route<dynamic>> initialRouteMap = {};
  int get currentTab => _currentTab;
  int get tabCount => _navigatorStateKeys.length;

  static MultiNavigatorTabHostState of(BuildContext context) {
    return context.findAncestorStateOfType<MultiNavigatorTabHostState>();
  }

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.initialTabCount; i++)
      _navigatorStateKeys.add(new GlobalKey());
    _titles.addAll(widget.initialTabNames);
  }

  void setTitle(BuildContext context, String title) {
    var key = _navigatorStateKeys.firstWhere((element) {
      return element.currentState == Navigator.of(context);
    });
    final int index = _navigatorStateKeys.indexOf(key);
    if (_titles[index] != title) {
      setState(() {
        _titles[index] = title;
      });
    }
  }

  String getTitle(int index) {
    return _titles[index];
  }

  void addTab(String title,
      {bool focusOnNewTab,
      String routeName,
      Object arguments,
      Route<dynamic> route}) {
    addTabAt(_navigatorStateKeys.length, title,
        focusOnNewTab: focusOnNewTab,
        route: route,
        routeName: routeName,
        arguments: arguments);
  }

  void addTabAt(int index, String title,
      {bool focusOnNewTab,
      String routeName,
      Object arguments,
      Route<dynamic> route}) {
    if (index < 0 || index > _navigatorStateKeys.length) {
      throw FormatException("Index is out of bound");
    }

    if (routeName == null && route == null)
      throw Exception("Either Specify the Route or RouteName");

    setState(() {
      if (routeName != null) {
        initialRouteSettingsMap[index] =
            RouteSettings(name: routeName, arguments: arguments);
      } else {
        initialRouteMap[index] = route;
      }
      if (index == _navigatorStateKeys.length) {
        _navigatorStateKeys.add(GlobalKey());
        _titles.add(title);
        if (focusOnNewTab != null && focusOnNewTab)
          _currentTab = _navigatorStateKeys.length - 1;
      } else {
        _titles.insert(index, title);
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
      if (index < currentTab) _currentTab--;
      if (_currentTab == _navigatorStateKeys.length - 1) _currentTab--;
      _navigatorStateKeys.removeAt(index);
      _titles.removeAt(index);
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
    List<Widget> tabs = [];
    for (int index = 0; index < tabCount; index++) {
      Widget tab;
      if (_titles[index] == null)
        tab = SizedBox();
      else
        tab = widget.onCreateTab(context, index, _navigatorStateKeys.length,
            currentTab == index, _titles[index]);
      if (tab == null) {
        throw Exception("Tab cant be null. Tab with index $index is null.");
      }
      tabs.add(tab);
    }
    return tabs;
  }

  Widget _getTabScrollWidget(BuildContext iContext) {
    return Container(
      color: widget.tabBarBackgroundColor,
      child: Align(
        alignment: widget.alignment,
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
              if (!widget.bottomTabs) _getTabScrollWidget(iContext),
              Expanded(
                child: IndexedStack(
                  index: currentTab,
                  children: _getNavigatorsWidgets(),
                ),
              ),
              if (widget.bottomTabs) _getTabScrollWidget(iContext),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _getNavigatorsWidgets() {
    List<Widget> navigators = [];
    for (int i = 0; i < _navigatorStateKeys.length; i++) {
      navigators.add(
        Navigator(
          key: _navigatorStateKeys[i],
          onUnknownRoute: widget.onUnknownRoute,
          initialRoute: _navigatorStateKeys[i].currentState == null &&
                  initialRouteSettingsMap.containsKey(i)
              ? initialRouteSettingsMap[i].name
              : widget.initialRoute,
          onGenerateRoute: (routeSettings) {
            if (initialRouteMap.containsKey(i)) {
              var route = initialRouteMap[i];
              initialRouteMap.clear();
              return route;
            }
            return widget.pageRouteCallback(routeSettings, i);
          },
        ),
      );
    }
    initialRouteSettingsMap.clear();
    return navigators;
  }
}
