import 'package:my_injector/src/AppComponent/repository_module.dart';

import 'package:jugger/jugger.dart';

import 'package:example1/app.dart';
import 'app_module.dart';

import 'interactor_module.dart';

@Component(modules: <Type>[AppModule, RepositoryModule, InteractorModule])
abstract class AppComponent {
  Logger logger();

  Tracker tracker();

  IArticlesScreenInteractor articlesScreenInteractor();

  IDetailArticleScreenInteractor detailArticleScreenInteractor();
}
