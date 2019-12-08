import 'package:example1/app.dart';

import 'package:jugger/jugger.dart';
import 'package:my_injector/src/AppComponent/app_component.dart';

import '../../my_injector.dart';

@Component(dependencies: [AppComponent])
abstract class ArticlesScreenComponent {
  void inject(ArticlesScreenState target);
}

@componentBuilder
abstract class ArticlesScreenComponentBuilder {
  ArticlesScreenComponentBuilder appComponent(AppComponent component);

  ArticlesScreenComponent build();
}

extension ArticlesScreenInject on ArticlesScreenState {
  void inject() {
    final ArticlesScreenComponent component =
        JuggerArticlesScreenComponentBuilder()
            .appComponent(Injector.of(context).appComponent)
            .build();
    component.inject(this);
  }
}
