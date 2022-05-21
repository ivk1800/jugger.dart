// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  Map<String, Item> get items;

  Map<String, Item> getItems();
}

@module
abstract class AppModule {
  @provides
  static Map<String, Item> provideItems() => const <String, Item>{};
}

class Item {}
