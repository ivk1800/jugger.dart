// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  Config getName();
  Config get name;
}

class Config {
  @inject
  const Config();
}
