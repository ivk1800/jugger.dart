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
          assert(
            error.toString() ==
                'Bad state: constructor can not be private [MyClass._]',
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
          assert(
            error.toString() ==
                'Bad state: not found injected constructor for MyClass',
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
          assert(
            error.toString() ==
                'Bad state: too many injected constructors for MyClass',
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
          assert(
            error.toString() ==
                'Bad state: factory constructor not supported [MyClass.create]',
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
          assert(
            error.toString() ==
                'Bad state: named constructor not supported [MyClass.create]',
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
          print(error);
          expect(
            error.toString(),
            'Bad state: all parameters must be Positional or Named [MyClass]',
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
          assert(
            // TODO(Ivan): https://github.com/ivk1800/jugger.dart/issues/3
            error.toString() == 'Stack Overflow',
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
            assert(
              error.toString() ==
                  'Bad state: not found injected constructor for MyClass',
            );
          },
        );
      });
    });
  });
}
