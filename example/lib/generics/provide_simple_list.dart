// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  List<Item> get items;
  List<Item> getItems();
}

@module
abstract class AppModule {
  @provides
  static List<Item> provideItems() => const <Item>[];
}

class Item {}
