import 'package:example1/app.dart';

import 'package:jugger/jugger.dart';
import 'package:my_injector/src/AppComponent/app_component.dart';

import '../../my_injector.dart';
import 'detail_article_screen_module.dart';

@Component(modules: [DetailArticleScreenModule], dependencies: [AppComponent])
abstract class DetailArticleScreenComponent {
  void inject(DetailArticleScreenState target);
}

@componentBuilder
abstract class DetailArticleScreenComponentBuilder {
  DetailArticleScreenComponentBuilder appComponent(AppComponent component);

  DetailArticleScreenComponentBuilder screen(DetailArticleScreenState screen);

  DetailArticleScreenComponent build();
}

extension DetailArticleScreenInject on DetailArticleScreenState {
  void inject() {
    final DetailArticleScreenComponent component =
        JuggerDetailArticleScreenComponentBuilder()
            .appComponent(Injector.of(context).appComponent)
            .build();
    component.inject(this);
  }
}
