import 'package:build/build.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('module', () {
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
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_build_method',
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
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#wrong_type_of_build_method',
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
              'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_component_dependency');
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
    test('bind wrong type', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[Module1])
abstract class AppComponent {}

@Module()
abstract class Module1 {
  @binds
  Pattern bindPattern(int impl);
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: bind_wrong_type:\n'
            'Method Module1.bindPattern parameter type must be assignable to the return type.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#bind_wrong_type',
          );
        },
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
            'error: type_not_supported:\n'
            'Type String? not supported.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#type_not_supported',
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
            'error: type_not_supported:\n'
            'Type void Function() not supported.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#type_not_supported',
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
            'error: type_not_supported:\n'
            'Type String? not supported.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#type_not_supported',
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
            'error: type_not_supported:\n'
            'Type String Function() not supported.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#type_not_supported',
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
            'error: type_not_supported:\n'
            'Type int? not supported.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#type_not_supported',
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
            'error: type_not_supported:\n'
            'Type int Function() not supported.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#type_not_supported',
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
            'error: type_not_supported:\n'
            'Type String? not supported.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#type_not_supported',
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
            'error: type_not_supported:\n'
            'Type int Function() not supported.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#type_not_supported',
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
            'error: type_not_supported:\n'
            'Type String? not supported.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#type_not_supported',
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
            'error: type_not_supported:\n'
            'Type int Function() not supported.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#type_not_supported',
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
            'error: type_not_supported:\n'
            'Type String? not supported.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#type_not_supported',
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
            'error: type_not_supported:\n'
            'Type String? not supported.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#type_not_supported',
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
    test('abstract method without bind annotation', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[Module1])
abstract class AppComponent {}

@Module()
abstract class Module1 {
  Pattern bindPattern(String impl);
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: missing_bind_annotation:\n'
            'Found abstract method Module1.bindPattern, but is not annotated with @Binds.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_bind_annotation',
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
            'error: public_module:\n'
            'Module _Module must be public.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#public_module',
          );
        },
      );
    });

    test('abstract module', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[Module])
abstract class AppComponent {}

@module
class Module {}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: abstract_module:\n'
            'Module Module must be abstract\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#abstract_module',
          );
        },
      );
    });

    test('module annotation required', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[Module])
abstract class AppComponent {}

abstract class Module {}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: module_annotation_required:\n'
            'The Module is missing an annotation Module.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#module_annotation_required',
          );
        },
      );
    });

    test('static method without provide annotation', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[Module1])
abstract class AppComponent {}

@Module()
abstract class Module1 {
  static String provideString() => '';
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: missing_provides_annotation:\n'
            'Found static method Module1.provideString, but is not annotated with @Provides.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_provides_annotation',
          );
        },
      );
    });

    test('abstract or static method', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[Module1])
abstract class AppComponent {}

@Module()
abstract class Module1 {
  @provides
  String providerString() => '';
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: unsupported_method_type:\n'
            'Method Module1.providerString must be abstract or static.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#unsupported_method_type',
          );
        },
      );
    });

    test('private method', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[Module1])
abstract class AppComponent {}

@Module()
abstract class Module1 {
  @provides
  static String _providerString() => '';
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: private_method_of_module:\n'
            'Method Module1._providerString can not be private.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#private_method_of_module',
          );
        },
      );
    });

    test('binds and provides together', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[Module1])
abstract class AppComponent {}

@Module()
abstract class Module1 {
  @binds
  @provides
  Pattern bindPattern(String impl);
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: ambiguity_of_provide_method:\n'
            'Method [Module1.bindPattern] can not be annotated together with @Provides and @Binds\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#ambiguity_of_provide_method',
          );
        },
      );
    });

    test('ambiguity of provide method', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[Module1])
abstract class AppComponent {}

@Module()
abstract class Module1 {
  @binds
  @provides
  Pattern bindPattern(String impl);
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: ambiguity_of_provide_method:\n'
            'Method [Module1.bindPattern] can not be annotated together with @Provides and @Binds\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#ambiguity_of_provide_method',
          );
        },
      );
    });

    test('provides nullable type', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {}

@module
abstract class AppModule {
  @provides
  static String? providesString() => '';
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: type_not_supported:\n'
            'Type String? not supported.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#type_not_supported',
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
            'error: repeated_modules:\n'
            'Repeated modules [AppModule] not allowed.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#repeated_modules',
          );
        },
      );
    });

    test('repeated modules in includes', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[FirstModule])
abstract class AppComponent {
  String getString();
}

@Module(includes: <Type>[SecondModule, SecondModule])
abstract class FirstModule {
  @provides
  static String provideString() => '';
}

@module
abstract class SecondModule {
  @provides
  static String provideString() => '';
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: repeated_modules:\n'
            'Repeated modules [SecondModule] not allowed.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#repeated_modules',
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
            'error: public_component:\n'
            'Component _Component must be public.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#public_component',
          );
        },
      );
    });

    test('abstract component', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component()
class AppComponent {}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: abstract_component:\n'
            'Component AppComponent must be abstract.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#abstract_component',
          );
        },
      );
    });

    test('not component a dependency', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(dependencies: <Type>[int])
abstract class AppComponent {}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: invalid_component_dependency:\n'
            'Dependency int is not allowed, only other components are allowed.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_component_dependency',
          );
        },
      );
    });

    test('component depend himself', () async {
      await checkBuilderError(
        codeContent: '''
import 'package:jugger/jugger.dart';

@Component(dependencies: <Type>[AppComponent])
abstract class AppComponent {}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: component_depend_himself:\n'
            'A component AppComponent cannot depend on himself.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#component_depend_himself',
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
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#public_component_builder',
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
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#component_builder_invalid_method_type',
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
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#wrong_arguments_of_build_method',
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
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#component_builder_type_provides_multiple_times',
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
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#component_builder_private_method',
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
