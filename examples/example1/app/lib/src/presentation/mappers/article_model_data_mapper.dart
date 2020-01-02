import 'package:example1/src/core/abstract_data_mapper.dart';
import 'package:example1/src/domain/objects/objects.dart';
import 'package:example1/src/presentation/models/models.dart';
import 'package:jugger/jugger.dart';

class ArticleModelDataMapper extends AbstractDataMapper<Article, ArticleModel> {
  @inject
  @singleton
  const ArticleModelDataMapper();

  @override
  ArticleModel transform(Article value) {
    return ArticleModel(
      id: value.id,
      title: value.title,
      description: value.description,
    );
  }
}
