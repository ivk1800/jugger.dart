import 'package:flutter/material.dart';

import 'src/app/widget/my_app.dart';
import 'src/di/app_component.dart';
import 'src/di/app_component.jugger.dart';

void main() {
  final IAppComponent appComponent =
      JuggerAppComponentBuilder().navigationKey(MyApp.navigationKey).build();

  runApp(
    MyApp(
      initial: appComponent.packagesListScreenFactory.create(),
    ),
  );
}
