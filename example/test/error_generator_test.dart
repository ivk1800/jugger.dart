import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('module', () {
    test('should failed if provide method not abstract or static', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String get testString;
}

@module
abstract class AppModule {
  @provides
  String provideTestString() => '';
}
        ''',
        onError: (Object error) {
          assert(
            error.toString() ==
                'Bad state: provided method must be abstract or static [AppModule.provideTestString]',
          );
        },
      );
    });
  });
}
