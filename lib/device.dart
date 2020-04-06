library device;

import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:math';
import 'dart:async';
import 'package:animations/animations.dart';
import 'package:community_material_icon/community_material_icon.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart'
    as ext;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'bluetooth/bluetooth.dart';
import 'bluetooth/controller.dart';
import 'widgets/keep_alive.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'bloc.dart';
import 'generated/i18n.dart';
import 'widgets/icon_text.dart';

part 'device/light.dart';

part 'device/rumble.dart';

part 'device/color.dart';

part 'device/components.dart';

const double _kTabBarHeight = 48;

class DeviceWidget extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceWidget({Key key, @required this.device}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DeviceWidgetState();
}

class _DeviceWidgetState extends State<DeviceWidget> {
  Controller _controller;

  BluetoothDevice get _device => widget.device;

  @override
  void initState() {
    print('device -> initState');
    super.initState();
//  _controller = Controller.test(_device);
    _controller = Controller(_device);
  }

  @override
  void dispose() {
    print('device -> dispose');
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('device -> build');
    final DeviceType type = DeviceType.of(context);
    Widget child = type.isPhone
        ? _Phone(_controller)
        : type.isTable ? _Tablet(_controller) : _Desktop(_controller);
    assert(child != null);
    return MultiProvider(
      providers: [
        Provider.value(value: _device),
        Provider.value(value: _controller),
      ],
      child: Selector<BluetoothDeviceRecord, DeviceState>(
        selector: (_, r) => r[_device],
        child: child,
        builder: (context, state, child) {
          if (state != DeviceState.CONNECTED &&
              ModalRoute.of(context).isCurrent) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showDialog(context, _device);
            });
          }
          return child;
        },
      ),
    );
  }
}

void _showDialog(BuildContext context, BluetoothDevice device) {
  Navigator.of(context).push(
    DialogRoute(
      barrierDismissible: false,
      pageBuilder: (context, animation, ___) {
        return WillPopScope(
          onWillPop: () async => false,
          child: FadeScaleTransition(
            animation: animation,
            child: AlertDialog(
              title: const Icon(CommunityMaterialIcons.alert),
              content: Text(
                S.of(context).dialog_desc_disconnected(
                    '${device.name}(${device.address})'),
                textAlign: TextAlign.center,
              ),
              actions: [
                FlatButton(
                  textTheme: ButtonTextTheme.accent,
                  child: Text(S.of(context).action_ok),
                  onPressed: () {
                    Navigator.popUntil(
                      context,
                      (route) => route.isFirst,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _Phone extends StatefulWidget {
  final Controller controller;

  const _Phone(this.controller);

  @override
  State<StatefulWidget> createState() => _PhoneState();
}

class _PhoneState extends State<_Phone> {
  PageController _controller;
  ValueNotifier<int> _index;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _index = ValueNotifier(_controller.initialPage);
  }

  @override
  void dispose() {
    _index.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final S s = S.of(context);
    return ValueListenableProvider.value(
      value: _index,
      child: Scaffold(
        body: ext.NestedScrollView(
          pinnedHeaderSliverHeightBuilder: () =>
              _kTabBarHeight + MediaQuery.of(context).padding.top,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              title: Text(widget.controller.device.name),
              centerTitle: true,
              floating: true,
              pinned: true,
              forceElevated: innerBoxIsScrolled,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(_kTabBarHeight),
                child: Container(
                  height: _kTabBarHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Consumer<int>(
                    builder: (context, value, _) {
                      return GNav(
                        onTabChange: (index) => _controller.animateToPage(
                          index,
                          duration: kDuration,
                          curve: Curves.easeInOut,
                        ),
                        selectedIndex: value,
                        gap: 8,
                        iconSize: 20,
                        duration: kDuration,
                        color: theme.colorScheme.onPrimary.withOpacity(0.4),
                        activeColor: theme.colorScheme.onPrimary,
                        tabBackgroundColor: theme.primaryColorDark,
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 16),
                        tabs: [
                          GButton(
                            icon: CommunityMaterialIcons.infinity,
                            text: 'test',
                          ),
                          GButton(
                            icon: CommunityMaterialIcons.wrench_outline,
                            text: s.bottom_label_general,
                          ),
                          GButton(
                            icon: CommunityMaterialIcons.palette_outline,
                            text: s.bottom_label_color,
                          ),
                          GButton(
                            icon: CommunityMaterialIcons.lightbulb_outline,
                            text: s.bottom_label_light,
                          ),
                          GButton(
                            icon: CommunityMaterialIcons.vibrate,
                            text: s.bottom_label_rumble,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
          body: PageView(
            controller: _controller,
            onPageChanged: (index) => _index.value = index,
            children: [
              const SizedBox(),
              KeepAliveWidgetBuilder(
                child: ListView(
                  children: [
                    Text('info'),
                    Card(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: _DeviceInfo(widget.controller),
                    ),
                    Text('button'),
                    Card(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: _DeviceButton(widget.controller),
                    ),
                    Text('axis'),
                    Card(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: _DeviceAxis(widget.controller),
                    ),
                    Text('memory'),
                    Card(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: _DeviceMemory(),
                    ),
                  ],
                ),
              ),
              KeepAliveWidgetBuilder(
                child: SingleChildScrollView(
                  child: ListBody(
                    children: [
                      Text('color'),
                      Card(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: _DeviceColor(widget.controller),
                      ),
                    ],
                  ),
                ),
              ),
              KeepAliveWidgetBuilder(
                child: SingleChildScrollView(
                  child: ListBody(
                    children: [
                      Text('light'),
                      Card(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: _DevicePlayerLight(widget.controller),
                      ),
                      Card(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: _DeviceHomeLight(widget.controller),
                      ),
                    ],
                  ),
                ),
              ),
              KeepAliveWidgetBuilder(
                child: SingleChildScrollView(
                  child: ListBody(
                    children: [
                      Text('rumble'),
                      Card(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: _DeviceRumble(widget.controller),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneState2 extends State<_Phone> {
  PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final S s = S.of(context);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: ext.NestedScrollView(
          pinnedHeaderSliverHeightBuilder: () =>
              _kTabBarHeight + MediaQuery.of(context).padding.top,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              title: Text(widget.controller.device.name),
              centerTitle: true,
              floating: true,
              pinned: true,
              forceElevated: innerBoxIsScrolled,
              bottom: TabBar(
                tabs: [
                  GButton(
                    icon: CommunityMaterialIcons.wrench_outline,
                    text: s.bottom_label_general,
                  ),
                  Tab(
                    icon: const Icon(CommunityMaterialIcons.palette_outline),
                    text: s.bottom_label_color,
                  ),
                  Tab(
                    icon: const Icon(CommunityMaterialIcons.lightbulb_outline),
                    text: s.bottom_label_light,
                  ),
                  Tab(
                    icon: const Icon(CommunityMaterialIcons.vibrate),
                    text: s.bottom_label_rumble,
                  ),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              KeepAliveWidgetBuilder(
                child: ListView(
                  children: [
                    Text('info'),
                    Card(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: _DeviceInfo(widget.controller),
                    ),
                    Text('button'),
                    Card(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: _DeviceButton(widget.controller),
                    ),
                    Text('axis'),
                    Card(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: _DeviceAxis(widget.controller),
                    ),
                    Text('memory'),
                    Card(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: _DeviceMemory(),
                    ),
                  ],
                ),
              ),
              KeepAliveWidgetBuilder(
                child: SingleChildScrollView(
                  child: ListBody(
                    children: [
                      Text('color'),
                      Card(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: _DeviceColor(widget.controller),
                      ),
                    ],
                  ),
                ),
              ),
              KeepAliveWidgetBuilder(
                child: SingleChildScrollView(
                  child: ListBody(
                    children: [
                      Text('light'),
                      Card(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: _DevicePlayerLight(widget.controller),
                      ),
                      Card(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: _DeviceHomeLight(widget.controller),
                      ),
                    ],
                  ),
                ),
              ),
              KeepAliveWidgetBuilder(
                child: SingleChildScrollView(
                  child: ListBody(
                    children: [
                      Text('rumble'),
                      Card(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: _DeviceRumble(widget.controller),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tablet extends StatelessWidget {
  final Controller controller;

  const _Tablet(this.controller);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tablet'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800),
          child: StaggeredGridView.count(
            primary: false,
            crossAxisCount: 2,
            mainAxisSpacing: 0,
            crossAxisSpacing: 0,
            padding: const EdgeInsets.all(16),
            staggeredTiles: [
              // general
              //const StaggeredTile.fit(2),
              const StaggeredTile.fit(2),
              const StaggeredTile.fit(1),
              const StaggeredTile.fit(1),
              const StaggeredTile.fit(1),
              const StaggeredTile.fit(1),
              // color
              //const StaggeredTile.fit(1),
              const StaggeredTile.fit(1),
              // light
              //const StaggeredTile.fit(2),
              const StaggeredTile.fit(1),
              const StaggeredTile.fit(1),
              // rumble
              //const StaggeredTile.fit(1),
              const StaggeredTile.fit(1),
            ],
            children: [
              //Text('General'),
              Card(child: _DeviceInfo(controller)),
              Card(child: _DeviceButton(controller)),
              Card(child: _DeviceAxis(controller)),
              Card(child: _DeviceMemory()),
              Card(child: _DeviceLogger()),
              //Text('Color'),
              Card(child: _DeviceColor(controller)),
              //Text('Light'),
              Card(child: _DevicePlayerLight(controller)),
              Card(child: _DeviceHomeLight(controller)),
              //Text('Rumble'),
              Card(child: _DeviceRumble(controller)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Desktop extends StatelessWidget {
  final Controller controller;

  const _Desktop(this.controller);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Desktop'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1200),
          child: StaggeredGridView.count(
            primary: false,
            crossAxisCount: 3,
            mainAxisSpacing: 0,
            crossAxisSpacing: 0,
            padding: const EdgeInsets.all(16),
            staggeredTiles: [
              const StaggeredTile.fit(1),
              const StaggeredTile.fit(1),
              const StaggeredTile.fit(1),
              const StaggeredTile.fit(1),
              const StaggeredTile.fit(1),
              const StaggeredTile.fit(1),
              const StaggeredTile.fit(1),
              const StaggeredTile.fit(1),
            ],
            children: [
              Card(child: _DeviceInfo(controller)),
              Card(child: _DeviceButton(controller)),
              Card(child: _DeviceAxis(controller)),
              Card(child: _DeviceMemory()),
              Card(child: _DeviceColor(controller)),
              Card(child: _DevicePlayerLight(controller)),
              Card(child: _DeviceHomeLight(controller)),
              Card(child: _DeviceRumble(controller)),
            ],
          ),
        ),
      ),
    );
  }
}

class DialogRoute<T> extends PopupRoute<T> {
  DialogRoute({
    @required RoutePageBuilder pageBuilder,
    bool barrierDismissible = true,
    String barrierLabel,
    Color barrierColor = const Color(0x80000000),
    Duration transitionDuration = const Duration(milliseconds: 200),
    RouteTransitionsBuilder transitionBuilder,
    RouteSettings settings,
  })  : assert(barrierDismissible != null),
        _pageBuilder = pageBuilder,
        _barrierDismissible = barrierDismissible,
        _barrierLabel = barrierLabel,
        _barrierColor = barrierColor,
        _transitionDuration = transitionDuration,
        _transitionBuilder = transitionBuilder,
        super(settings: settings);

  final RoutePageBuilder _pageBuilder;

  @override
  bool get barrierDismissible => _barrierDismissible;
  final bool _barrierDismissible;

  @override
  String get barrierLabel => _barrierLabel;
  final String _barrierLabel;

  @override
  Color get barrierColor => _barrierColor;
  final Color _barrierColor;

  @override
  Duration get transitionDuration => _transitionDuration;
  final Duration _transitionDuration;

  final RouteTransitionsBuilder _transitionBuilder;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return Semantics(
      child: _pageBuilder(context, animation, secondaryAnimation),
      scopesRoute: true,
      explicitChildNodes: true,
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    if (_transitionBuilder == null) {
      return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.linear,
          ),
          child: child);
    } // Some default transition
    return _transitionBuilder(context, animation, secondaryAnimation, child);
  }
}
