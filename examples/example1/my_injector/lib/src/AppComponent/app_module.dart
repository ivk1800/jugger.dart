import 'package:example1/app.dart';
import 'package:example1/main.dart';
import 'package:jugger/jugger.dart';

@module
abstract class AppModule {
  @provide
  @singleton
  static Logger provideLogger() {
    return Logger();
  }

  @provide
  @singleton
  static Tracker provideTracker() {
    return Tracker();
  }

  @singleton
  @provide
  static INavigationRouter provideNavigationRouter() {
    return NavigationRouteImpl(
      navigationKey: MyApp.navigatorKey,
    );
  }
}
