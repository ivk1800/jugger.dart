import 'package:example1/src/domain/objects/objects.dart';
import 'package:rxdart/rxdart.dart';

abstract class IDetailArticleScreenInteractor {
  Observable<DetailArticle> getDetailArticle(int id);
}
