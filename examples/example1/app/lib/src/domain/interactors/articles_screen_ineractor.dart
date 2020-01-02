import 'package:example1/src/domain/objects/objects.dart';
import 'package:rxdart/rxdart.dart';

abstract class IArticlesScreenInteractor {
  Observable<List<Article>> get articles;

  void openDetailArticlesScreen(int articleId);
}
