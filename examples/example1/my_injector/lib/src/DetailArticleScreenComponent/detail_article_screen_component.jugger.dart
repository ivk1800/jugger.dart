// ignore_for_file: implementation_imports
// ignore_for_file: prefer_const_constructors
import 'package:example1/src/presentation/mappers/detail_article_model_data_mapper.dart'
    as _i1;
import 'package:example1/src/presentation/blocs/detail_article_screen_bloc.dart'
    as _i2;
import 'package:my_injector/src/DetailArticleScreenComponent/detail_article_screen_component.dart'
    as _i3;
import 'package:my_injector/src/AppComponent/app_component.dart' as _i4;
import 'package:example1/src/presentation/screens/detail_article_screen.dart'
    as _i5;
import 'package:jugger/jugger.dart' as _i6;
import 'package:my_injector/src/DetailArticleScreenComponent/detail_article_screen_module.dart'
    as _i7;

class JuggerDetailArticleScreenComponentBuilder
    implements _i3.DetailArticleScreenComponentBuilder {
  _i4.AppComponent _appComponent;

  _i5.DetailArticleScreenState _detailArticleScreenState;

  @override
  _i3.DetailArticleScreenComponentBuilder appComponent(
      _i4.AppComponent component) {
    _appComponent = component;
    return this;
  }

  @override
  _i3.DetailArticleScreenComponentBuilder screen(
      _i5.DetailArticleScreenState screen) {
    _detailArticleScreenState = screen;
    return this;
  }

  @override
  _i3.DetailArticleScreenComponent build() {
    assert(_appComponent != null);
    assert(_detailArticleScreenState != null);
    ;
    return JuggerDetailArticleScreenComponent._create(
        _appComponent, _detailArticleScreenState);
  }
}

class JuggerDetailArticleScreenComponent
    implements _i3.DetailArticleScreenComponent {
  JuggerDetailArticleScreenComponent._create(
      this._appComponent, this._detailArticleScreenState) {
    _init();
  }

  _i6.IProvider<int> _intProvider;

  _i6.IProvider<_i1.DetailArticleModelDataMapper>
      _detailArticleModelDataMapperProvider;

  _i6.IProvider<_i2.DetailArticleBloc> _detailArticleBlocProvider;

  final _i4.AppComponent _appComponent;

  final _i5.DetailArticleScreenState _detailArticleScreenState;

  void _init() {
    _initProvides();
  }

  void _initProvides() {
    _intProvider = _i6.Provider<int>(() {
      return _i7.DetailArticleScreenModule.provideArticleId(
          _detailArticleScreenState);
    });
    _detailArticleModelDataMapperProvider =
        _i6.SingletonProvider<_i1.DetailArticleModelDataMapper>(() {
      return _i1.DetailArticleModelDataMapper();
    });
    _detailArticleBlocProvider = _i6.Provider<_i2.DetailArticleBloc>(() {
      return _i2.DetailArticleBloc(
          interactor: _appComponent.detailArticleScreenInteractor(),
          articleModelDataMapper: _detailArticleModelDataMapperProvider.get(),
          articleId: _intProvider.get());
    });
  }

  @override
  void inject(_i5.DetailArticleScreenState target) {
    target.bloc = _detailArticleBlocProvider.get();
  }
}
