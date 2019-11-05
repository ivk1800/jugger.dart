import 'package:example1/src/domain/interactors/detail_article_screen_ineractor.dart';
import 'package:example1/src/presentation/mappers/detail_article_model_data_mapper.dart';
import 'package:example1/src/presentation/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:jugger/jugger.dart';
import 'base_bloc.dart';

class DetailArticleBloc extends BaseBloc {
  @inject
  DetailArticleBloc({
    @required IDetailArticleScreenInteractor interactor,
    @required DetailArticleModelDataMapper articleModelDataMapper
  })
      : _interactor = interactor,
        _articleModelDataMapper = articleModelDataMapper;

  final IDetailArticleScreenInteractor _interactor;
  final DetailArticleModelDataMapper _articleModelDataMapper;

  void setData(int articleId) {
    _articleId = articleId;
  }

  int _articleId;

  Observable<DetailArticleModel> get article => _interactor
      .getDetailArticle(_articleId)
      .map(_articleModelDataMapper.transform);
}
