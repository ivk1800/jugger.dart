import 'package:example1/src/presentation/screens/articles_screen.dart';
import 'package:example1/src/presentation/widgets/injector_widget.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Injector(
        navigationKey: navigatorKey,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Flutter Demo',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            platform: TargetPlatform.iOS,
          ),
          home: ArticlesScreen(),
        ));
  }
}
