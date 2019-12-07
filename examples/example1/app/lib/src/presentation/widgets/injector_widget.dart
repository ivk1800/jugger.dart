import 'package:example1/app.dart';
import 'package:example1/src/presentation/screens/articles_screen.dart';
import 'package:example1/src/presentation/screens/detail_article_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_injector/my_injector.dart';

class Injector extends StatefulWidget {
  const Injector({Key key, @required this.child, this.navigationKey})
      : super(key: key);

  final Widget child;
  final GlobalKey<NavigatorState> navigationKey;

  @override
  InjectorState createState() => InjectorState();

  static InjectorState of(BuildContext context) {
    final InjectorState navigator =
        context.ancestorStateOfType(const TypeMatcher<InjectorState>());
    return navigator;
  }
}

class InjectorState extends State<Injector> implements MyComponent {
  JuggerMyComponent _myComponent;

  @override
  void initState() {
    _myComponent = JuggerMyComponentBuilder()
        .tracker(Tracker())
        .token('123').build();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void injectArticlesScreen(ArticlesScreenState target) {
    _myComponent.injectArticlesScreen(target);
  }

  @override
  void injectDetailArticleScreen(DetailArticleScreenState target) {
    _myComponent.injectDetailArticleScreen(target);
  }
}
