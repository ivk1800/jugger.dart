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
    IDetailArticleScreenInteractor interactor,
    @required DetailArticleModelDataMapper articleModelDataMapper,
    @required int articleId,
  })
      : _interactor = interactor,
        _articleModelDataMapper = articleModelDataMapper,
        _articleId = articleId;

  final IDetailArticleScreenInteractor _interactor;
  final DetailArticleModelDataMapper _articleModelDataMapper;

  final int _articleId;

  Observable<DetailArticleModel> get article => _interactor
      .getDetailArticle(_articleId)
      .map(_articleModelDataMapper.transform);
}
