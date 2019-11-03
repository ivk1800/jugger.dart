import 'package:example1/src/core/abstract_data_mapper.dart';
import 'package:example1/src/domain/objects/objects.dart';
import 'package:example1/src/presentation/models/models.dart';
import 'package:jugger/jugger.dart';

class DetailArticleModelDataMapper extends AbstractDataMapper<DetailArticle, DetailArticleModel> {

  @inject
  @singleton
  const DetailArticleModelDataMapper();

  @override
  DetailArticleModel transform(DetailArticle value) {
    return DetailArticleModel(
      id: value.id,
      title: value.title,
      description: value.description,
    );
  }
}