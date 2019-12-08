import 'package:example1/app.dart';
import 'package:jugger/jugger.dart';

@module
abstract class DetailArticleScreenModule {

  @provide
  static int provideArticleId(DetailArticleScreenState screen) {
    return screen.widget.articlesId;
  }
}