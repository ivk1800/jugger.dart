import 'package:build/build.dart';
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
          expect(
            error.toString(),
            'error: provided method must be abstract or static [AppModule.provideTestString]',
          );
        },
      );
    });

    test('circular includes', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent {
  String get string;
}

@Module(includes: <Type>[Module2])
abstract class Module1 {
  @provides
  static String providerString(int i) => '';
}

@Module(includes: <Type>[Module1])
abstract class Module2 {
  @provides
  static int providerInt() => 0;
}

        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: Found circular included modules!',
          );
        },
      );
    });
  });

  group('constructor', () {
    test('should failed if single private constructor', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String get hello;
}

@module
abstract class AppModule {
  @provides
  static String provideHello(MyClass myClass) => myClass.toString();
}

class MyClass {
  @inject
  MyClass._();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: constructor can not be private [MyClass._]',
          );
        },
      );
    });

    test('should failed if not injected constructor', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String get hello;
}

@module
abstract class AppModule {
  @provides
  static String provideHello(MyClass myClass) => myClass.toString();
}

class MyClass {
  MyClass();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: not found injected constructor for MyClass',
          );
        },
      );
    });

    test('should failed if multiple injected constructors', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String get hello;
}

@module
abstract class AppModule {
  @provides
  static String provideHello(MyClass myClass) => myClass.toString();
}

class MyClass {
  @inject
  MyClass();
  
  @inject
  MyClass.create();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: too many injected constructors for MyClass',
          );
        },
      );
    });

    test('should failed if injected factory constructor', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String get hello;
}

@module
abstract class AppModule {
  @provides
  static String provideHello(MyClass myClass) => myClass.toString();
}

class MyClass {
  MyClass._();
  
  @inject
  factory MyClass.create() {
    return MyClass._();
  }
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: factory constructor not supported [MyClass.create]',
          );
        },
      );
    });

    test('should failed if injected named constructor', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String get hello;
}

@module
abstract class AppModule {
  @provides
  static String provideHello(MyClass myClass) => myClass.toString();
}

class MyClass {
  @inject
  MyClass.create();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: named constructor not supported [MyClass.create]',
          );
        },
      );
    });

    test('should failed if injected constructor with named param', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String get hello;
}

@module
abstract class AppModule {
  @provides
  static String provideHello(MyClass myClass) => myClass.toString();

  @provides
  static int provideNumberInt() => 1;

  @provides
  static double provideNumberDouble() => 1;
}

class MyClass {
  @inject
  const MyClass(
    this.numberInt, {
    required this.numberDouble,
  });

  final int numberInt;
  final double numberDouble;
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: all parameters must be Positional or Named [MyClass]',
          );
        },
      );
    });
  });

  group('inject', () {
    test('should failed if injected class from core', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  List<String> get strings;
}

@module
abstract class AppModule {
  @provides
  static List<String> provideStrings(String s) => <String>[s];
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: Provider for (String) not found',
          );
        },
      );
    });

    test('should failed if injected abstract class from core', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  List<String> get strings;
}

@module
abstract class AppModule {
  @provides
  static List<String> provideStrings(Future<String> f) => <String>[f.toString()];
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: [Future<String>, qualifier: null] not provided',
          );
        },
      );
    });
  });

  group('circular dependency', () {
    test('should failed if two providers depend on each other', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String get appName;
  int get appVersion;
}

@module
abstract class AppModule {
  @provides
  static String provideAppName(int appVersion) => '';

  @provides
  static int provideAppVersion(String appName) => 1;
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: Found circular dependency! provideAppName->provideAppVersion->provideAppName',
          );
        },
      );
    });

    test('should failed if depend through binds type', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

class Router implements IRouter {
  @inject
  Router(String s);
}


abstract class IRouter {}

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String get hello;
}

@module
abstract class AppModule {
  @provides
  static String provideHello(IRouter router) => router.toString();

  @binds
  IRouter bindRouter(Router impl);
}

class MyClass {
  @inject
  MyClass();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: Found circular dependency! provideHello->bindRouter->provideHello',
          );
        },
      );
    });

    test('should failed if depend through injected constructor', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String get hello;
}

@module
abstract class AppModule {
  @provides
  static int provideInt(String string) => string.length;

  @provides
  static String provideHello(MyClass myClass) => myClass.toString();
}

class MyClass {
  @inject
  MyClass(int number);
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: Found circular dependency! provideInt->provideHello->provideInt',
          );
        },
      );
    });

    group('annotation', () {
      test('should failed if inject annotation not from jugger library',
          () async {
        await checkBuilderError(
          codeContent: '''
import 'package:jugger/jugger.dart' as j;

@j.Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String get hello;
}

@j.module
abstract class AppModule {
  @j.provides
  static String provideHello(MyClass myClass) => myClass.toString();
}

class MyClass {
  @inject
  MyClass._();
}

class Inject {
  const factory Inject() = Inject._;

  const Inject._();
}

const Inject inject = Inject._();

        ''',
          onError: (Object error) {
            expect(
              error.toString(),
              'error: not found injected constructor for MyClass',
            );
          },
        );
      });
    });
  });

  group('subcomponent', () {
    test('should failed if component builder not found', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

class AppConfig {
  AppConfig(this.hello);

  final String hello;
}

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  AppConfig get appConfig;
}

@module
abstract class AppModule {
  @singleton
  @provides
  static AppConfig provideAppConfig() => AppConfig('hello');
}

@Component(
  dependencies: <Type>[AppComponent],
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  String get helloString;
}

@module
abstract class MyModule {
  @provides
  static String provideHelloString(AppConfig config) => config.hello;
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: you need provide dependencies by builder. component: MyComponent, dependencies: AppComponent',
          );
        },
      );
    });

    test('should failed if build method not found', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

class AppConfig {
  AppConfig(this.hello);

  final String hello;
}

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  AppConfig get appConfig;
}

@module
abstract class AppModule {
  @singleton
  @provides
  static AppConfig provideAppConfig() => AppConfig('hello');
}

@Component(
  dependencies: <Type>[AppComponent],
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  String get helloString;
}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponentBuilder appComponent(AppComponent appComponent);
}

@module
abstract class MyModule {
  @provides
  static String provideHelloString(AppConfig config) => config.hello;
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: missing_build_method:\n'
            'Missing required build method of MyComponentBuilder package:example/test.dart.dart\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_build_method#missing_build_method',
          );
        },
      );
    });

    test('should failed if build method return not component type', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

class AppConfig {
  AppConfig(this.hello);

  final String hello;
}

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  AppConfig get appConfig;
}

@module
abstract class AppModule {
  @singleton
  @provides
  static AppConfig provideAppConfig() => AppConfig('hello');
}

@Component(
  dependencies: <Type>[AppComponent],
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  String get helloString;
}

@componentBuilder
abstract class AppComponentBuilder {
  AppComponentBuilder appComponent(AppComponent appComponent);
  
  AppComponentBuilder build();
}

@module
abstract class MyModule {
  @provides
  static String provideHelloString(AppConfig config) => config.hello;
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: wrong_type_of_build_method:\n'
            'build method of AppComponentBuilder return wrong type.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_build_method#wrong_type_of_build_method',
          );
        },
      );
    });

    test('should failed if dependency not provided by build method', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

class AppConfig {
  AppConfig(this.hello);

  final String hello;
}

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  AppConfig get appConfig;
}

@module
abstract class AppModule {
  @singleton
  @provides
  static AppConfig provideAppConfig() => AppConfig('hello');
}

@Component(
  dependencies: <Type>[AppComponent],
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  String get helloString;
}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponent build();
}

@module
abstract class MyModule {
  @provides
  static String provideHelloString(AppConfig config) => config.hello;
}
        ''',
        onError: (Object error) {
          expect(
              error.toString(),
              'error: missing_component_dependency:\n'
              'Dependency (AppComponent) not provided.\n'
              'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_build_method#missing_component_dependency');
        },
      );
    });

    test(
        'should failed if dependency provided multiple time from parent component and module',
        () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

class AppConfig {
  AppConfig(this.hello);

  final String hello;
}

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  AppConfig get appConfig;
}

@module
abstract class AppModule {
  @singleton
  @provides
  static AppConfig provideAppConfig() => AppConfig('hello');
}

@Component(
  dependencies: <Type>[AppComponent],
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  String get helloString;
}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponentBuilder appComponent(AppComponent appComponent);

  MyComponent build();
}

@module
abstract class MyModule {
  @provides
  static AppConfig provideAppConfig() => AppConfig('hello');

  @provides
  static String provideHelloString(AppConfig config) => config.hello;
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: AppConfig provides multiple time: AppConfig.appConfig, MyModule.provideAppConfig',
          );
        },
      );
    });
  });

  group('build config', () {
    test('should failed if found unused providers', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

class MainRouter {}

@Component(modules: <Type>[AppModule])
abstract class AppComponent {}

@module
abstract class AppModule {
  @provides
  static String provideString() => '';
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: found unused generated providers: _stringProvider',
          );
        },
        options: const BuilderOptions(
          <String, dynamic>{
            'check_unused_providers': true,
          },
        ),
      );
    });
  });

  group('qualifier', () {
    test('should failed if named qualifier not found', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

class AppConfig {}

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  @Named('my')
  String getString();
}

@module
abstract class AppModule {}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: [String, qualifier: my] not provided',
          );
        },
      );
    });

    test('should failed if qualifier not found', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

class AppConfig {}

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  @my
  String getString();
}

@module
abstract class AppModule {}

@qualifier
class My {
  const My();
}

const My my = My();
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: [String, qualifier: My] not provided',
          );
        },
      );
    });

    test('should failed if multiple qualifiers', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

class AppConfig {}

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  @Named('name')
  @Named('name1')
  AppConfig get appConfig;
}

@module
abstract class AppModule {
  @provides
  @Named('name')
  static AppConfig provideAppConfig() => AppConfig();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: multiple qualifiers not allowed [AppComponent.appConfig]',
          );
        },
      );
    });
  });

  group('injectable field', () {
    test('private injectable field', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

class InjectableClass {
  @inject
  late String _helloString;
}

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  void inject(InjectableClass c);
}

@module
abstract class AppModule {
  @singleton
  @provides
  static String provideString() => 'hello';
}

        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: field _helloString must be only public',
          );
        },
        options: const BuilderOptions(
          <String, dynamic>{
            'check_unused_providers': true,
          },
        ),
      );
    });
  });

  group('binds', () {
    test('binds wrong type', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

abstract class IMainRouter {}

class MainRouter implements IMainRouter {
  const MainRouter();
}

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  IMainRouter getMainRouter();
}

@module
abstract class AppModule {
  @singleton
  @provides
  static MainRouter provideMainRouter() => const MainRouter();

  @singleton
  @binds
  IMainRouter bindMainRouter(String impl);
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: bindMainRouter bind wrong type IMainRouter',
          );
        },
        options: const BuilderOptions(
          <String, dynamic>{
            'check_unused_providers': true,
          },
        ),
      );
    });

    test('binds class without injected constructor', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

abstract class IMainRouter {}

class MainRouter implements IMainRouter {
  const MainRouter();
}

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  IMainRouter getMainRouter();
}

@module
abstract class AppModule {
  @binds
  IMainRouter bindMainRouter(MainRouter impl);
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: not found injected constructor for MainRouter',
          );
        },
      );
    });
  });

  group('unsupported type', () {
    test('nullable component getter with String type', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  String? get name;
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: type [String?] not supported',
          );
        },
        options: const BuilderOptions(
          <String, dynamic>{
            'check_unused_providers': true,
          },
        ),
      );
    });

    test('nullable component getter with Function type', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  void Function() get name;
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: type [void Function()] not supported',
          );
        },
        options: const BuilderOptions(
          <String, dynamic>{
            'check_unused_providers': true,
          },
        ),
      );
    });

    test('nullable parameter in injected constructor', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  Config get config;
}

class Config {
  @inject
  const Config(this.name);

  final String? name;
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: type [String?] not supported',
          );
        },
        options: const BuilderOptions(
          <String, dynamic>{
            'check_unused_providers': true,
          },
        ),
      );
    });

    test('function parameter in injected constructor', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  Config get config;
}

class Config {
  @inject
  const Config(this.nameProvider);

  final String Function() nameProvider;
}        
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: type [String Function()] not supported',
          );
        },
        options: const BuilderOptions(
          <String, dynamic>{
            'check_unused_providers': true,
          },
        ),
      );
    });

    test('provider method return nullable type', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {}

@module
abstract class AppModule {
  @provides
  static int? provideInt() => 0;
}
        
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: type [int?] not supported',
          );
        },
        options: const BuilderOptions(
          <String, dynamic>{
            'check_unused_providers': true,
          },
        ),
      );
    });

    test('provider method return function type', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {}

@module
abstract class AppModule {
  @provides
  static int Function() provideInt() => () => 0;
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: type [int Function()] not supported',
          );
        },
        options: const BuilderOptions(
          <String, dynamic>{
            'check_unused_providers': true,
          },
        ),
      );
    });

    test('nullable parameter in provide method', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {}

@module
abstract class AppModule {
  @provides
  static int provideInt(String? version) => 0;
}        
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: type [String?] not supported',
          );
        },
        options: const BuilderOptions(
          <String, dynamic>{
            'check_unused_providers': true,
          },
        ),
      );
    });

    test('function parameter in provide method', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {}

@module
abstract class AppModule {
  @provides
  static int provideInt(int Function() version) => 0;
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: type [int Function()] not supported',
          );
        },
        options: const BuilderOptions(
          <String, dynamic>{
            'check_unused_providers': true,
          },
        ),
      );
    });

    test('build instance nullable type', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  String get string;
}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponentBuilder appComponent(String? s);

  AppComponent build();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: type [String?] not supported',
          );
        },
        options: const BuilderOptions(
          <String, dynamic>{
            'check_unused_providers': true,
          },
        ),
      );
    });

    test('build instance function type', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  String get string;
}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponentBuilder appComponent(int Function() s);

  AppComponent build();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: type [int Function()] not supported',
          );
        },
        options: const BuilderOptions(
          <String, dynamic>{
            'check_unused_providers': true,
          },
        ),
      );
    });

    test('binds nullable type', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {}

@module
abstract class AppModule {
  @binds
  String? bindString(String impl);
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: type [String?] not supported',
          );
        },
        options: const BuilderOptions(
          <String, dynamic>{
            'check_unused_providers': true,
          },
        ),
      );
    });

    test('binds impl nullable type', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {}

@module
abstract class AppModule {
  @binds
  String bindString(String? impl);
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: type [String?] not supported',
          );
        },
        options: const BuilderOptions(
          <String, dynamic>{
            'check_unused_providers': true,
          },
        ),
      );
    });
  });

  group('module', () {
    test('abstract provide method', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[Module])
abstract class AppComponent {
  String getString();
}

@module
abstract class Module {
  @provides
  String provideString();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: provide abstract method [Module.provideString] must be annotated [Binds]',
          );
        },
      );
    });

    test('public module', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[_Module])
abstract class AppComponent {}

@module
abstract class _Module {}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: Module [abstract class _Module] must be public',
          );
        },
      );
    });
  });

  group('component', () {
    test(
      'should fail if class with qualifier, but constructor is injected',
      () async {
        await checkBuilderError(
          codeContent: '''
import 'package:jugger/jugger.dart';

class MyClass {
  @inject
  const MyClass();
}

@Component()
abstract class AppComponent {
  @Named('test')
  MyClass getMyClass();
}
        ''',
          onError: (Object error) {
            expect(
              error.toString(),
              'error: [MyClass, qualifier: test] not provided',
            );
          },
        );
      },
    );

    test('repeated modules', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule, AppModule])
abstract class AppComponent {
  String getString();
}

@module
abstract class AppModule {
  @provides
  static String provideString() => '';
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: repeated modules [AppModule] not allowed',
          );
        },
      );
    });

    test('public component', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[])
abstract class _Component {}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: Component [abstract class _Component] must be public',
          );
        },
      );
    });

    test('public component builder', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[])
abstract class AppComponent {}

@componentBuilder
abstract class _MyComponentBuilder {
  AppComponent build();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: public_component_builder:\n'
            'Component builder _MyComponentBuilder must be public.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_build_method#public_component_builder',
          );
        },
      );
    });

    test('component builder invalid method type', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {}

@componentBuilder
abstract class ComponentBuilder {
  AppComponent setInt(int i);

  AppComponent build();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: component_builder_invalid_method_type:\n'
            'Invalid type of method setInt. Expected ComponentBuilder.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_build_method#component_builder_invalid_method_type',
          );
        },
      );
    });

    test('wrong arguments of build method', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {}

@componentBuilder
abstract class ComponentBuilder {
  AppComponent build(int i);
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: wrong_arguments_of_build_method:\n'
            'Build method should not contain arguments.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_build_method#wrong_arguments_of_build_method',
          );
        },
      );
    });

    test('component builder type provided multiple times', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  String get string;
}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponentBuilder setString(String s);

  MyComponentBuilder setString2(String s);

  AppComponent build();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: component_builder_type_provided_multiple_times:\n'
            'Type String provided multiple times in component builder MyComponentBuilder\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_build_method#component_builder_type_provides_multiple_times',
          );
        },
      );
    });

    test('component builder method must be public', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  String get string;
}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponentBuilder _setString(String s);

  AppComponent build();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: component_builder_private_method:\n'
            'Method _setString must be public.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_build_method#component_builder_private_method',
          );
        },
      );
    });
  });

  group('injected method', () {
    test('static method', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  MyClass getMyClass();
}

@module
abstract class AppModule {
  @provides
  static int provideInt() => 0;
}

class MyClass {
  @inject
  const MyClass();

  @inject
  static void init(int i) {}
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: injected method [init] can not be static',
          );
        },
      );
    });

    test('abstract method', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  MyClass getMyClass();
}

@module
abstract class AppModule {
  @provides
  static int provideInt() => 0;
}

class MyClass extends BaseClass {
  @inject
  const MyClass();

  @override
  void init(int i) {}
}

abstract class BaseClass {
  const BaseClass();

  @inject
  void init(int i);
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: injected method [init] can not be abstract',
          );
        },
      );
    });
  });
}
