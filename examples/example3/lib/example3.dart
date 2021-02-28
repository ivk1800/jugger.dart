library example3;

import 'package:jugger/jugger.dart';

abstract class IDataFormatter {
  String defaultFormat(int timestamp);
}

class DataFormatter implements IDataFormatter {
  @inject
  const DataFormatter();

  @override
  String defaultFormat(int timestamp) {
    return timestamp.toString();
  }
}

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  IDataFormatter getDataFormatter();

  void inject(MyClass target);
}

@module
abstract class AppModule {
  @singleton
  @bind
  IDataFormatter bindDataFormatter(DataFormatter impl);
}

class MyClass {
  @inject
  late IDataFormatter dataFormatter;
}
