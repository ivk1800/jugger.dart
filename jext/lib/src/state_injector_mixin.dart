import 'package:flutter/widgets.dart';

import 'component_holder.dart';

mixin StateInjectorMixin<W extends StatefulWidget, S extends State<W>>
    on State<W> {
  @override
  void initState() {
    final ComponentHolderState<W, S> findAncestorStateOfType =
        context.findAncestorStateOfType<ComponentHolderState<W, S>>()!;
    findAncestorStateOfType.inject(this as S);
    super.initState();
  }
}
