// ignore_for_file: avoid_classes_with_only_static_members
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  List<Item> get items;
}

@module
abstract class AppModule {}

class Item {}

@componentBuilder
abstract class IAppComponentBuilder {
  IAppComponentBuilder items(List<Item> value);

  AppComponent build();
}
