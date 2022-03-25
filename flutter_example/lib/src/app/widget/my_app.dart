import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({required this.initial, Key? key}) : super(key: key);

  final Widget initial;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigationKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: initial,
    );
  }

  static GlobalKey<NavigatorState> navigationKey = GlobalKey<NavigatorState>();
}
