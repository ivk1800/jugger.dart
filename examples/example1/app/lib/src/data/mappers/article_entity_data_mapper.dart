import 'package:example1/src/core/abstract_data_mapper.dart';
import 'package:example1/src/data/entities/entities.dart';
import 'package:example1/src/domain/objects/objects.dart';
import 'package:jugger/jugger.dart';

class ArticleEntityDataMapper extends AbstractDataMapper<ArticleEntity, Article> {

  @inject
  @singleton
  const ArticleEntityDataMapper();

  @override
  Article transform(ArticleEntity value) {
    return Article(
      id: value.id,
      title: value.title,
      description: value.description,
    );
  }
}