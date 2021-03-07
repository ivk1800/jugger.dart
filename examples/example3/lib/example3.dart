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

////////////////////////////////////////////////////////////////////////////////

class AuthPageState implements ResultDispatcher<UserCredentials> {
  @inject
  late AuthScreenViewModel viewModel;

  @override
  void dispatchResult(UserCredentials result) {
    // TODO: implement dispatchResult
  }
}

abstract class ResultDispatcher<T> {
  void dispatchResult(T result);
}

class AuthScreenViewModel {

  @inject
  AuthScreenViewModel(this.resultDispatcher, this.data);

  final ResultDispatcher<UserCredentials> resultDispatcher;
  final Map<int, List<String>> data;
}

@Component(
    modules: <Type>[AuthScreenModule], dependencies: <Type>[AppComponent])
abstract class AuthScreenComponent {
  void inject(AuthPageState target);
}

@componentBuilder
abstract class AuthScreenComponentBuilder {
  AuthScreenComponentBuilder appComponent(AppComponent component);

  AuthScreenComponentBuilder screen(AuthPageState screen);

  AuthScreenComponent build();
}

@module
abstract class AuthScreenModule {
  @provide
  static ResultDispatcher<UserCredentials> provideResultDispatcher(
      AuthPageState screen) {
    return screen;
  }

  @provide
  static Map<int, List<String>> provideData() {
    return <int, List<String>>{};
  }
}

class UserCredentials {
  UserCredentials(this.token);

  final String token;
}

////////////////////////////////////////////////////////////////////////////////
