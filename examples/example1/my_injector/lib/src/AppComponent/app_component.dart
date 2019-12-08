import 'package:my_injector/src/AppComponent/repository_module.dart';

import 'app_module.dart';

import 'package:jugger/jugger.dart';
import 'package:example1/app.dart';

import 'interactor_module.dart';

@Component(modules: [AppModule, RepositoryModule, InteractorModule])
abstract class AppComponent {

  Logger logger();

  Tracker tracker();

  IArticlesScreenInteractor articlesScreenInteractor();

  IDetailArticleScreenInteractor detailArticleScreenInteractor();
}