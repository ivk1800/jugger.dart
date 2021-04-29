import 'package:flutter/widgets.dart';
import 'package:jugger/jugger.dart' as j;

abstract class IWidgetStateComponent<W extends StatefulWidget,
    S extends State<W>> implements j.IDisposable {
  void inject(S screen);
}
