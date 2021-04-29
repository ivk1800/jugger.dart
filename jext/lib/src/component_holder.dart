import 'package:flutter/widgets.dart';
import 'package:jext/jext.dart';

typedef ComponentFactory<W extends StatefulWidget, S extends State<W>>
    = IWidgetStateComponent<W, S> Function(S state);

class ComponentHolder<W extends StatefulWidget, S extends State<W>>
    extends StatefulWidget {
  const ComponentHolder(
      {Key? key, required this.componentFactory, required this.child})
      : super(key: key);

  final ComponentFactory<W, S> componentFactory;
  final Widget child;

  @override
  ComponentHolderState<W, S> createState() => ComponentHolderState<W, S>();
}

class ComponentHolderState<W extends StatefulWidget, S extends State<W>>
    extends State<ComponentHolder<W, S>> {
  IWidgetStateComponent<W, S>? _component;

  @override
  Widget build(BuildContext context) => widget.child;

  void inject(S state) {
    _component ??= widget.componentFactory(state);
    _component!.inject(state);
  }

  @override
  void dispose() {
    _component?.dispose();
    _component = null;
    super.dispose();
  }
}
