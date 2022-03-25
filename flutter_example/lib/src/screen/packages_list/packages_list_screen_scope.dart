import 'package:flutter/widgets.dart';

import 'di/packages_list_screen_component.dart';
import 'packages_list_bloc.dart';

class PackagesListScreenScope extends StatefulWidget {
  const PackagesListScreenScope({
    Key? key,
    required this.child,
    required this.create,
  }) : super(key: key);

  final Widget child;
  final IPackagesListScreenComponent Function() create;

  @override
  State<PackagesListScreenScope> createState() =>
      _PackagesListScreenScopeState();

  static PackagesListBloc getPackagesListBloc(BuildContext context) =>
      _InheritedScope.of(context)._packagesListBloc;
}

class _PackagesListScreenScopeState extends State<PackagesListScreenScope> {
  late final IPackagesListScreenComponent _component = widget.create.call();

  late final PackagesListBloc _packagesListBloc =
      _component.getPackagesListBloc();

  @override
  Widget build(BuildContext context) {
    return _InheritedScope(
      holderState: this,
      child: widget.child,
    );
  }
}

class _InheritedScope extends InheritedWidget {
  const _InheritedScope({
    Key? key,
    required Widget child,
    required _PackagesListScreenScopeState holderState,
  })  : _state = holderState,
        super(key: key, child: child);

  final _PackagesListScreenScopeState _state;

  static _PackagesListScreenScopeState of(BuildContext context) {
    final _PackagesListScreenScopeState? result = (context
            .getElementForInheritedWidgetOfExactType<_InheritedScope>()
            ?.widget as _InheritedScope?)
        ?._state;
    assert(result != null, 'No PackagesListScreenScope found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(_InheritedScope oldWidget) => false;
}
