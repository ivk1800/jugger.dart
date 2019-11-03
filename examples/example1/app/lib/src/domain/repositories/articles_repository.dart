import 'package:example1/src/domain/objects/objects.dart';
import 'package:rxdart/rxdart.dart';

abstract class IArticlesRepository {
  Observable<List<Article>> get articles;

  Observable<DetailArticle> getDetailArticle(int id);
}