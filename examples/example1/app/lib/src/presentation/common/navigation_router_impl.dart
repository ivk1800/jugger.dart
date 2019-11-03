import 'package:example1/src/core/navigation_router.dart';
import 'package:example1/src/presentation/screens/detail_article_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class NavigationRouteImpl implements INavigationRouter {

  NavigationRouteImpl({@required GlobalKey<NavigatorState> navigationKey})
      : _navigationKey = navigationKey;

  final GlobalKey<NavigatorState> _navigationKey;

  @override
  void openDetailArticleScreen(int articlesId) {
    _navigationKey.currentState.push<dynamic>(MaterialPageRoute<dynamic>(builder: (BuildContext context) {
      return DetailArticleScreen(
        articlesId: articlesId,
      );
    }));
  }
}
