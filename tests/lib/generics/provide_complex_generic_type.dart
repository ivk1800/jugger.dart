// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  Map<Map<String, Item>, Map<String, Map<String, Item>>> get items;

  Map<Map<String, Item>, Map<String, Map<String, Item>>> getItems();
}

@module
abstract class AppModule {
  @provides
  static Map<Map<String, Item>, Map<String, Map<String, Item>>>
      provideItems() =>
          const <Map<String, Item>, Map<String, Map<String, Item>>>{};
}

class Item {}
