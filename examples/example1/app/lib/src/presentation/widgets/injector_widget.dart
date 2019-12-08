import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_injector/my_injector.dart';

class Injector extends StatefulWidget {
  const Injector({Key key, @required this.child, this.navigationKey})
      : super(key: key);

  final Widget child;
  final GlobalKey<NavigatorState> navigationKey;

  @override
  InjectorState createState() => InjectorState();

  static InjectorState of(BuildContext context) {
    final InjectorState navigator =
        context.ancestorStateOfType(const TypeMatcher<InjectorState>());
    return navigator;
  }
}

class InjectorState extends State<Injector> {
  JuggerAppComponent _appComponent;

  JuggerAppComponent get appComponent => _appComponent;

  @override
  void initState() {
    _appComponent = JuggerAppComponent.create();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
