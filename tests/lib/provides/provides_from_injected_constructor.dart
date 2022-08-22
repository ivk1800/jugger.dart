// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

class MainRouter {
  @inject
  MainRouter();
}

class MainViewModel {
  MainViewModel(this.router);

  final MainRouter router;
}

////////////////////////////////////////////////////////////////////////////////

@Component(modules: <Type>[AppModule])
@singleton
abstract class AppComponent {
  MainViewModel getMainViewModel();
}

@module
abstract class AppModule {
  @singleton
  @provides
  static MainViewModel provideMainViewModel(
    MainRouter router,
  ) =>
      MainViewModel(router);
}
