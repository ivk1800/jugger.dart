import 'package:build/build.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('multibindings', () {
    group('set', () {
      test('multiple multibinding annotation', () async {
        await checkBuilderResult(
          mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent {
  Set<String> get strings;
}

@module
abstract class Module1 {
  @provides
  @intoSet
  @intoMap
  static String provideString1() => '1';
}
        ''',
          onError: (Object error) {
            expect(
              error.toString(),
              'error: multiple_multibinding_annotation:\n'
              'Methods cannot have more than one multibinding annotation:\n'
              'Module1.provideString1\n'
              'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#multiple_multibinding_annotation\n'
              'package:tests/test.dart:15:17\n'
              '   ╷\n'
              '15 │   static String provideString1() => \'1\';\n'
              '   │                 ^^^^^^^^^^^^^^\n'
              '   ╵',
            );
          },
        );
      });

      test('unused multibinding', () async {
        await checkBuilderResult(
          mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent {}

@module
abstract class Module1 {
  @provides
  @intoSet
  static String provideString1() => '1';
}
        ''',
          onError: (Object error) {
            expect(
              error.toString(),
              'error: unused_multibinding:\n'
              'Multibindings Set<String> is declared, but not used.\n'
              'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#unused_multibinding',
            );
          },
        );
      });

      test('depend by self type', () async {
        await checkBuilderResult(
          mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent {
  Set<String> get strings;
}

@module
abstract class Module1 {
  @provides
  @intoSet
  static String provideString1(String s) => '1';
}
        ''',
          onError: (Object error) {
            expect(
              error.toString(),
              'error: provider_not_found:\n'
              'Provider for String not found.\n'
              'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#provider_not_found',
            );
          },
        );
      });
    });

    group('map', () {
      test('duplicates keys', () async {
        await checkBuilderResult(
          mainContent: '''
// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent {
  Map<int, String> get strings;
}

@module
abstract class Module1 {
  @provides
  @intoMap
  @IntKey(1)
  static String provideString1() => '1';

  @provides
  @intoMap
  @IntKey(1)
  static String provideString2() => '2';
}
        ''',
          onError: (Object error) {
            expect(
              error.toString(),
              'error: multibindings_duplicates_keys:\n'
              'Multibindings not allowed with duplicates keys:\n'
              'Module1.provideString1\n'
              'Module1.provideString2\n'
              'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#multibindings_duplicates_keys',
            );
          },
        );
      });

      test('duplicates keys from multiple modules', () async {
        await checkBuilderResult(
          mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1, Module2],
)
abstract class AppComponent {
  Map<Type, String> get strings;
}

@module
abstract class Module1 {
  @provides
  @intoMap
  @TypeKey(String)
  static String provideString1() => '1';
}

@module
abstract class Module2 {
  @provides
  @intoMap
  @TypeKey(String)
  static String provideString2() => '2';
}
        ''',
          onError: (Object error) {
            expect(
              error.toString(),
              'error: multibindings_duplicates_keys:\n'
              'Multibindings not allowed with duplicates keys:\n'
              'Module1.provideString1\n'
              'Module2.provideString2\n'
              'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#multibindings_duplicates_keys',
            );
          },
        );
      });

      test('missing key', () async {
        await checkBuilderResult(
          mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent {
  Map<int, String> get strings;
}

@module
abstract class Module1 {
  @provides
  @intoMap
  static String provideString1() => '1';
}
        ''',
          onError: (Object error) {
            expect(
              error.toString(),
              'error: multibindings_missing_key:\n'
              'Methods of type map must declare a map key:\n'
              'Module1.provideString1\n'
              'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#multibindings_missing_key\n'
              'package:tests/test.dart:14:17\n'
              '   ╷\n'
              '14 │   static String provideString1() => \'1\';\n'
              '   │                 ^^^^^^^^^^^^^^\n'
              '   ╵',
            );
          },
        );
      });

      test('multiple keys', () async {
        await checkBuilderResult(
          mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent {
  Map<int, String> get strings;
}

@module
abstract class Module1 {
  @provides
  @intoMap
  @IntKey(1)
  @IntKey(0)
  static String provideString2() => '2';
}
        ''',
          onError: (Object error) {
            expect(
              error.toString(),
              'error: multibindings_multiple_keys:\n'
              'Methods may not have more than one map key:\n'
              'Module1.provideString2\n'
              'keys: 1, 0\n'
              'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#multibindings_multiple_keys\n'
              'package:tests/test.dart:16:17\n'
              '   ╷\n'
              '16 │   static String provideString2() => \'2\';\n'
              '   │                 ^^^^^^^^^^^^^^\n'
              '   ╵',
            );
          },
        );
      });

      test('missing value field of key', () async {
        await checkBuilderResult(
          mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent {
  Map<bool, String> get strings;
}

@module
abstract class Module1 {
  @provides
  @intoMap
  @MyKey(false)
  static String provideString1() => '1';
}

@mapKey
class MyKey {
  const MyKey(this.value2);

  final bool key;
}
        ''',
          onError: (Object error) {
            expect(
              error.toString(),
              'error: multibindings_invalid_key:\n'
              'Unable resolve value. Did you forget to add value field?\n'
              'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#multibindings_invalid_key',
            );
          },
        );
      });

      test('unsupported type', () async {
        await checkBuilderResult(
          mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1],
)
abstract class AppComponent {
  Map<String, String> get strings;
}

@module
abstract class Module1 {
  @provides
  @intoMap
  @MyKey(Symbol("name"))
  static String provideString1() => '1';

  @provides
  @intoMap
  @MyKey(Symbol("name"))
  static String provideString2() => '2';
}

@mapKey
class MyKey {
  const MyKey(this.value);

  final Symbol value;
}
        ''',
          onError: (Object error) {
            expect(
              error.toString(),
              'error: multibindings_unsupported_key_type:\n'
              'Type Symbol (#name) unsupported.\n'
              'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#multibindings_unsupported_key_type',
            );
          },
        );
      });
    });
  });

  group('disposable component', () {
    test(
        'The component does not contain disposable objects, but the dispose method is declared.',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class MyComponent {
  MyClass getMyClass();

  Future<void> dispose();
}

class MyClass {
  @inject
  const MyClass();

  void dispose() {}
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: missing_disposables:\n'
            'The component MyComponent does not contain disposable objects, but the dispose method MyComponent.dispose is declared.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_disposables\n'
            'package:tests/test.dart:4:16\n'
            '  ╷\n'
            '4 │ abstract class MyComponent {\n'
            '  │                ^^^^^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('disposable type not supported with binds', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[AppModule],
)
@singleton
abstract class AppComponent {
  IMyClass getMyClass();

  Future<void> dispose();
}

@module
abstract class AppModule {
  @binds
  @singleton
  @disposable
  IMyClass bindMyClass(MyClassImpl impl);
}

abstract class IMyClass {}

class MyClassImpl implements IMyClass {
  @inject
  const MyClassImpl();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: disposable_not_supported:\n'
            'Disposable type IMyClass not supported with binds.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#disposable_not_supported',
          );
        },
      );
    });

    test('not found disposer for type', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';
import 'package:tests/injected_method/injected_multiple_parent_methods.dart';

@Component()
@singleton
abstract class AppComponent {
  MyClass getMyClass();

  Future<void> dispose();
}

@singleton
@Disposable(strategy: DisposalStrategy.delegated)
class MyClass {
  @inject
  const MyClass();

  void dispose() {}
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: missing_dispose_method:\n'
            'Not found disposer for MyClass.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_dispose_method',
          );
        },
      );
    });

    test(
        'found disposal handler for method, but he does not marked as disposable',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';
import 'package:tests/injected_method/injected_multiple_parent_methods.dart';

@Component(
  modules: <Type>[AppComponentModule],
)
abstract class AppComponent {
  MyClass getMyClass();

  Future<void> dispose();
}

@module
abstract class AppComponentModule {
  @disposalHandler
  static Future<void> disposeMyClass(MyClass myClass) async {
    myClass.dispose();
  }
}

class MyClass {
  @inject
  const MyClass();

  void dispose() {}
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: unused_disposal_handler:\n'
            'Found unused disposal handler AppComponentModule.disposeMyClass.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#unused_generated_providers\n'
            'package:tests/test.dart:16:23\n'
            '   ╷\n'
            '16 │   static Future<void> disposeMyClass(MyClass myClass) async {\n'
            '   │                       ^^^^^^^^^^^^^^\n'
            '   ╵',
          );
        },
      );
    });

    test('method annotated with DisposalHandler must have one parameter',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';
import 'package:tests/injected_method/injected_multiple_parent_methods.dart';

@Component(
  modules: <Type>[AppComponentModule],
)
abstract class AppComponent {
  MyClass getMyClass();

  Future<void> dispose();
}

@module
abstract class AppComponentModule {
  @disposalHandler
  static Future<void> disposeMyClass(MyClass myClass, MyClass myClass2) async {
    myClass.dispose();
  }
}

@singleton
@Disposable(strategy: DisposalStrategy.delegated)
class MyClass {
  @inject
  const MyClass();

  void dispose() {}
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: invalid_handler_method:\n'
            'Method AppComponentModule.disposeMyClass annotated with DisposalHandler must have one parameter.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_handler_method\n'
            'package:tests/test.dart:16:23\n'
            '   ╷\n'
            '16 │   static Future<void> disposeMyClass(MyClass myClass, MyClass myClass2) async {\n'
            '   │                       ^^^^^^^^^^^^^^\n'
            '   ╵',
          );
        },
      );
    });

    test('missing dispose method', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
@singleton
abstract class AppComponent {
  MyClass getMyClass();
}

@singleton
@disposable
class MyClass {
  @inject
  MyClass();

  void dispose() {}
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: missing_dispose_method:\n'
            'Missing dispose method of component AppComponent.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_dispose_method\n'
            'package:tests/test.dart:5:16\n'
            '  ╷\n'
            '5 │ abstract class AppComponent {\n'
            '  │                ^^^^^^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('wrong disposable handler return type', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[AppModule],
)
abstract class AppComponent {
  MyClass getMyClass();

  Future<void> dispose();
}

@module
abstract class AppModule {
  @disposalHandler
  static disposeMyClass(MyClass myClass) {
    myClass.dispose();
  }

  @provides
  @singleton
  @Disposable(strategy: DisposalStrategy.delegated)
  static MyClass provideMyClass() => MyClass();
}

class MyClass {
  void dispose() {}
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: invalid_handler_method:\n'
            'Disposal handler must return type Future<void> or void.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_handler_method\n'
            'package:tests/test.dart:15:10\n'
            '   ╷\n'
            '15 │   static disposeMyClass(MyClass myClass) {\n'
            '   │          ^^^^^^^^^^^^^^\n'
            '   ╵',
          );
        },
      );
    });

    test('abstract dispose handler', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1, Module2],
)
abstract class AppComponent {
  MyClass getMyClass();

  Future<void> dispose();
}

@Module(includes: <Type>[Module3])
abstract class Module1 {
  @provides
  @singleton
  @Disposable(strategy: DisposalStrategy.delegated)
  static MyClass provideMyClass() => MyClass();
}

@Module(includes: <Type>[Module3])
abstract class Module2 {}

@module
abstract class Module3 {
  @disposalHandler
  Future<void> disposeMyClass(MyClass myClass);
}

class MyClass {
  void dispose2() {}
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: invalid_handler_method:\n'
            'Method Module3.disposeMyClass marked with @DisposalHandler must be static.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_handler_method\n'
            'package:tests/test.dart:26:16\n'
            '   ╷\n'
            '26 │   Future<void> disposeMyClass(MyClass myClass);\n'
            '   │                ^^^^^^^^^^^^^^\n'
            '   ╵',
          );
        },
      );
    });

    test('multiple dispose handlers in multiple modules', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[Module1, Module2],
)
abstract class AppComponent {
  MyClass getMyClass();

  Future<void> dispose();
}

@module
abstract class Module1 {
  @disposalHandler
  static Future<void> disposeMyClass(MyClass myClass) async {
    myClass.dispose2();
  }

  @provides
  @singleton
  @Disposable(strategy: DisposalStrategy.delegated)
  static MyClass provideMyClass() => MyClass();
}

@module
abstract class Module2 {
  @disposalHandler
  static Future<void> disposeMyClass(MyClass myClass) async {
    myClass.dispose2();
  }
}

class MyClass {
  void dispose2() {}
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: multiple_disposal_handlers_for_type:\n'
            'Disposal handler for MyClass provided multiple times: Module1.disposeMyClass, Module2.disposeMyClass\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#multiple_disposal_handlers_for_type\n'
            'package:tests/test.dart:28:23\n'
            '   ╷\n'
            '28 │   static Future<void> disposeMyClass(MyClass myClass) async {\n'
            '   │                       ^^^^^^^^^^^^^^\n'
            '   ╵',
          );
        },
      );
    });

    test('multiple dispose handlers in one module', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[AppModule],
)
abstract class AppComponent {
  MyClass getMyClass();

  Future<void> dispose();
}

@module
abstract class AppModule {
  @disposalHandler
  static Future<void> disposeMyClass(MyClass myClass) async {
    myClass.dispose2();
  }

  @disposalHandler
  static Future<void> disposeMyClass2(MyClass myClass) async {
    myClass.dispose2();
  }

  @provides
  @singleton
  @Disposable(strategy: DisposalStrategy.delegated)
  static MyClass provideMyClass() => MyClass();
}

class MyClass {
  void dispose2() {}
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: multiple_disposal_handlers_for_type:\n'
            'Disposal handler for MyClass provided multiple times: AppModule.disposeMyClass, AppModule.disposeMyClass2\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#multiple_disposal_handlers_for_type\n'
            'package:tests/test.dart:20:23\n'
            '   ╷\n'
            '20 │   static Future<void> disposeMyClass2(MyClass myClass) async {\n'
            '   │                       ^^^^^^^^^^^^^^^\n'
            '   ╵',
          );
        },
      );
    });

    test('injected type marked as disposable, but not scoped.', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[AppComponentModule],
)
abstract class AppComponent {
  MyClass getMyClass();

  Future<void> dispose();
}

@module
abstract class AppComponentModule {
  @disposalHandler
  static Future<void> disposeMyClass(MyClass myClass) async {
    myClass.dispose();
  }
}

@Disposable(strategy: DisposalStrategy.delegated)
class MyClass {
  @inject
  const MyClass();

  void dispose() {}
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: disposable_not_scoped:\n'
            'MyClass marked as disposable, but not scoped.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#disposable_not_scoped',
          );
        },
      );
    });

    test('provided type marked as disposable, but not scoped.', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[AppModule],
)
abstract class AppComponent {
  MyClass getMyClass();

  Future<void> dispose();
}

@module
abstract class AppModule {
  @disposalHandler
  static Future<void> disposeMyClass(MyClass myClass) async {
    myClass.dispose2();
  }

  @provides
  @Disposable(strategy: DisposalStrategy.delegated)
  static MyClass provideMyClass() => MyClass();
}

class MyClass {
  void dispose2() {}
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: disposable_not_scoped:\n'
            'MyClass marked as disposable, but not scoped.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#disposable_not_scoped',
          );
        },
      );
    });

    test('auto disposable with declared handler', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[AppModule],
)
@singleton
abstract class AppComponent {
  MyClass getMyClass();

  Future<void> dispose();
}

@module
abstract class AppModule {
  @disposalHandler
  static Future<void> disposeMyClass(MyClass myClass) async {}

  @provides
  @singleton
  static MyClass provideMyClass() => MyClass();
}

class MyClass {}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: unused_disposal_handler:\n'
            'Found unused disposal handler AppModule.disposeMyClass.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#unused_generated_providers\n'
            'package:tests/test.dart:16:23\n'
            '   ╷\n'
            '16 │   static Future<void> disposeMyClass(MyClass myClass) async {}\n'
            '   │                       ^^^^^^^^^^^^^^\n'
            '   ╵',
          );
        },
      );
    });

    test('unused handler for type', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[AppModule],
)
@singleton
abstract class AppComponent {
  MyClass getMyClass();

  Future<void> dispose();
}

@module
abstract class AppModule {
  @disposalHandler
  static Future<void> disposeMyClass(MyClass myClass) async {
    myClass.dispose();
  }

  @provides
  @singleton
  @Disposable(strategy: DisposalStrategy.auto)
  static MyClass provideMyClass() => MyClass();
}

class MyClass {
  void dispose() {}
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: redundant_disposal_handler:\n'
            'MyClass marked as auto disposable, but declared handler AppModule.disposeMyClass.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#redundant_disposal_handler\n'
            'package:tests/test.dart:16:23\n'
            '   ╷\n'
            '16 │   static Future<void> disposeMyClass(MyClass myClass) async {\n'
            '   │                       ^^^^^^^^^^^^^^\n'
            '   ╵',
          );
        },
      );
    });

    test('missing dispose method on disposable object', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  builder: AppComponentBuilder,
)
abstract class AppComponent {
  MyClass1 getMyClass1();

  Future<void> dispose();
}

@componentBuilder
abstract class AppComponentBuilder {
  @disposable
  AppComponentBuilder setMyClass1(MyClass1 c);

  AppComponent build();
}

class MyClass1 {
  const MyClass1();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: missing_dispose_method:\n'
            'MyClass1 marked as auto disposable, but not found properly dispose method.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_dispose_method',
          );
        },
      );
    });

    test('invalid return type of  dispose method on disposable object',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  builder: AppComponentBuilder,
)
abstract class AppComponent {
  MyClass1 getMyClass1();

  Future<void> dispose();
}

@componentBuilder
abstract class AppComponentBuilder {
  @disposable
  AppComponentBuilder setMyClass1(MyClass1 c);

  AppComponent build();
}

class MyClass1 {
  const MyClass1();

  Future<int> dispose() async => 0;
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: missing_dispose_method:\n'
            'MyClass1 marked as auto disposable, but not found properly dispose method.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_dispose_method',
          );
        },
      );
    });

    test('invalid return type of dispose method', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  void dispose();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: invalid_handler_method:\n'
            'Dispose method dispose of component must have type Future<void>.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_handler_method\n'
            'package:tests/test.dart:5:8\n'
            '  ╷\n'
            '5 │   void dispose();\n'
            '  │        ^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('invalid parameters of dispose method', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  Future<void> dispose(int i);
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: invalid_handler_method:\n'
            'Disposal method dispose of component must have zero parameters.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_handler_method\n'
            'package:tests/test.dart:5:16\n'
            '  ╷\n'
            '5 │   Future<void> dispose(int i);\n'
            '  │                ^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });
  });

  group('missing provider', () {
    test('missing provider of type in injected constructor', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
@singleton
abstract class AppComponent {
  Foo getFoo();
}

@singleton
class Foo {
  @inject
  const Foo(this.i);

  final int i;
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: provider_not_found:\n'
            'Provider for int not found.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#provider_not_found\n'
            'The following entry points depend on int:\n'
            'Foo(int i)',
          );
        },
      );
    });

    test('missing provider of type for component', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  String getString();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: provider_not_found:\n'
            'Provider for String not found.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#provider_not_found',
          );
        },
      );
    });
    test('missing provider of type with qualifier for component', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  @Named('s')
  String getString();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: provider_not_found:\n'
            'Provider for String with qualifier s not found.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#provider_not_found',
          );
        },
      );
    });

    test('missing provider of type for module method arg', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String getString();
}

@module
abstract class AppModule {
  @provides
  static String provideString(int i) => '';
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: provider_not_found:\n'
            'Provider for int not found.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#provider_not_found\n'
            'The following entry points depend on int:\n'
            'AppModule.provideString(int i)',
          );
        },
      );
    });

    test('missing provider of type with qualifier for module method arg',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String getString();
}

@module
abstract class AppModule {
  @provides
  static String provideString(@Named('i') int i) => '';
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: provider_not_found:\n'
            'Provider for int with qualifier i not found.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#provider_not_found\n'
            'The following entry points depend on int:\n'
            'AppModule.provideString(@i int i)',
          );
        },
      );
    });

    test('missing provider of type for module method arg 2', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String getString();
}

@module
abstract class AppModule {
  @provides
  static String provideString(IProvider<int> i) => '';
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: provider_not_found:\n'
            'Provider for int not found.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#provider_not_found',
          );
        },
      );
    });

    test('missing provider of type with qualifier for module method arg 2',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String getString();
}

@module
abstract class AppModule {
  @provides
  static String provideString(@Named('i') IProvider<int> i) => '';
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: provider_not_found:\n'
            'Provider for int with qualifier i not found.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#provider_not_found',
          );
        },
      );
    });

    test(
        'if method of component annotated with qualifier, but constructor of class is in',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  @Named('s')
  MyClass getMyClass();
}

class MyClass {
  const MyClass();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: provider_not_found:\n'
            'Provider for MyClass with qualifier s not found.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#provider_not_found',
          );
        },
      );
    });
  });

  group('missing provider', () {
    test('unexpected error', () async {
      await checkBuilderResult(
        mainContent: '''
@Component()
abstract class AppComponent { }
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'Unable resolve valueElement. Annotated element: abstract class AppComponent\n'
            'Unexpected error, please report the issue: https://github.com/ivk1800/jugger.dart/issues/new?assignees=&labels=&template=code-generation-error.md&title=',
          );
        },
      );
    });
  });

  group('non lazy', () {
    test('unscoped non lazy', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[MyModule])
abstract class MyComponent {
  String getString();
}

@module
abstract class MyModule {
  @provides
  @nonLazy
  static String provideString() => "";
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: unscoped_non_lazy:\n'
            'It makes no sense to initialize a non-scoped object:\n'
            'MyModule.provideString\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#unscoped_non_lazy',
          );
        },
      );
    });
  });

  group('module', () {
    test('Multiple annotations on module', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent { }

@module
@module
abstract class AppModule { }
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: multiple_module_annotations:\n'
            'Multiple annotations on module AppModule not supported.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#multiple_module_annotations\n'
            'package:tests/test.dart:8:16\n'
            '  ╷\n'
            '8 │ abstract class AppModule { }\n'
            '  │                ^^^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('should failed if method with named param', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String get hello;
}

@module
abstract class AppModule {
  @provides
  static String provideHello(int numberInt, {
    required int numberDouble,
  }) => '';

  @provides
  static int provideNumberInt() => 1;

  @provides
  static double provideNumberDouble() => 1;
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: invalid_parameters_types:\n'
            'provideHello can have only positional parameters or only named parameters.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_parameters_types\n'
            'package:tests/test.dart:11:17\n'
            '   ╷\n'
            '11 │   static String provideHello(int numberInt, {\n'
            '   │                 ^^^^^^^^^^^^\n'
            '   ╵',
          );
        },
      );
    });

    test('circular includes', () async {
      await checkBuilderResult(
        mainContent: '''
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
            'error: circular_modules_dependency:\n'
            'Found circular included modules!\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#modules_circular_dependency\n'
            'package:tests/test.dart:11:16\n'
            '   ╷\n'
            '11 │ abstract class Module1 {\n'
            '   │                ^^^^^^^\n'
            '   ╵',
          );
        },
      );
    });
  });

  group('constructor', () {
    test('should failed if single private constructor', () async {
      await checkBuilderResult(
        mainContent: '''
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
            'error: invalid_injected_constructor:\n'
            'Constructor MyClass._ can not be private.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_injected_constructor\n'
            'package:tests/test.dart:16:11\n'
            '   ╷\n'
            '16 │   MyClass._();\n'
            '   │           ^\n'
            '   ╵',
          );
        },
      );
    });

    test('should failed if abstract class with injected constructor', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  MyClass get myClass;
}

abstract class MyClass {
  @inject
  const MyClass();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: missing_provider:\n'
            'Provider for MyClass not found.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_provider',
          );
        },
      );
    });

    test('should failed if missing provider for abstract class', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  MyClass get myClass;
}

abstract class MyClass {}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: missing_provider:\n'
            'Provider for MyClass not found.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_provider',
          );
        },
      );
    });

    test('should failed if not injected constructor', () async {
      await checkBuilderResult(
        mainContent: '''
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
            'error: missing_injected_constructor:\n'
            'Class MyClass cannot be provided without an @inject constructor.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_injected_constructor\n'
            'The following entry points depend on MyClass:\n'
            'AppModule.provideHello(MyClass myClass)',
          );
        },
      );
    });

    test('should failed if multiple injected constructors', () async {
      await checkBuilderResult(
        mainContent: '''
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
            'error: multiple_injected_constructors:\n'
            'Class MyClass may only contain one injected constructor.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#multiple_injected_constructors',
          );
        },
      );
    });
  });

  group('inject', () {
    test('should failed if injected class from core', () async {
      await checkBuilderResult(
        mainContent: '''
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
            'error: provider_not_found:\n'
            'Provider for String not found.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#provider_not_found\n'
            'The following entry points depend on String:\n'
            'AppModule.provideStrings(String s)',
          );
        },
      );
    });

    test('should failed if injected abstract class from core', () async {
      await checkBuilderResult(
        mainContent: '''
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
            'error: provider_not_found:\n'
            'Provider for Future<String> not found.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#provider_not_found\n'
            'The following entry points depend on Future<String>:\n'
            'AppModule.provideStrings(Future<String> f)',
          );
        },
      );
    });
  });

  group('circular dependency', () {
    test('should failed if two providers depend on each other', () async {
      await checkBuilderResult(
        mainContent: '''
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
            'error: circular_dependency:\n'
            'Found circular dependency! provideAppName->provideAppVersion->provideAppName\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#circular_dependency',
          );
        },
      );
    });

    test('should failed if depend through binds type', () async {
      await checkBuilderResult(
        mainContent: '''
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
            'error: circular_dependency:\n'
            'Found circular dependency! provideHello->bindRouter->provideHello\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#circular_dependency',
          );
        },
      );
    });

    test('should failed if depend through injected constructor', () async {
      await checkBuilderResult(
        mainContent: '''
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
            'error: circular_dependency:\n'
            'Found circular dependency! provideInt->provideHello->provideInt\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#circular_dependency',
          );
        },
      );
    });

    group('annotation', () {
      test('should failed if inject annotation not from jugger library',
          () async {
        await checkBuilderResult(
          mainContent: '''
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
              'error: missing_injected_constructor:\n'
              'Class MyClass cannot be provided without an @inject constructor.\n'
              'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_injected_constructor\n'
              'The following entry points depend on MyClass:\n'
              'AppModule.provideHello(MyClass myClass)',
            );
          },
        );
      });
    });
  });

  group('subcomponent', () {
    test('should failed if subcomponents with same name', () async {
      await checkBuilderResult(
        assets: <String, String>{
          'subcomponent1.dart': '''
import 'package:jugger/jugger.dart';

@Subcomponent()
abstract class MySubcomponent {}
          ''',
          'subcomponent2.dart': '''
import 'package:jugger/jugger.dart';

@Subcomponent()
abstract class MySubcomponent {}
          ''',
        },
        mainContent: '''
import 'package:jugger/jugger.dart';
import 'subcomponent1.dart' as s1;
import 'subcomponent1.dart' as s2;

@Component()
abstract class AppComponent {
  @subcomponentFactory
  s1.MySubcomponent createMyComponent1();

  @subcomponentFactory
  s2.MySubcomponent createMyComponent2();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: Subcomponents with the same name are not supported in the parent component.\n'
            'package:tests/test.dart:6:16\n'
            '  ╷\n'
            '6 │ abstract class AppComponent {\n'
            '  │                ^^^^^^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('should failed if circular dependencies of subcomponents', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class MyComponent {
  @subcomponentFactory
  MySubcomponent1 createMySubcomponent();
}

@Subcomponent()
abstract class MySubcomponent1 {
  @subcomponentFactory
  MySubcomponent2 createMySubcomponent();
}

@Subcomponent()
abstract class MySubcomponent2 {
  @subcomponentFactory
  MySubcomponent1 createMySubcomponent();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: circular_dependency:\n'
            'Found circular dependency! MyComponent->MySubcomponent1->MySubcomponent2->MySubcomponent1\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#circular_dependency',
          );
        },
      );
    });

    test('should failed if subcomponent contain factory for self', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class MyComponent {
  @subcomponentFactory
  MySubcomponent1 createMySubcomponent();
}

@Subcomponent()
abstract class MySubcomponent1 {
  @subcomponentFactory
  MySubcomponent1 createMySubcomponent();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: circular_dependency:\n'
            'Found circular dependency! MyComponent->MySubcomponent1->MySubcomponent1\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#circular_dependency',
          );
        },
      );
    });

    test('should failed if components with same scope', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';
import 'package:tests/util/scopes.dart';

@Component()
@scope1
abstract class MyComponent {
  @subcomponentFactory
  MySubcomponent createMySubcomponent();
}

@Subcomponent()
@scope1
abstract class MySubcomponent {}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: invalid_scope:\n'
            'The scope of the component must be different from the scope of the parent or should there be no scope.\n'
            'MySubcomponent: Scope1\n'
            'MyComponent: Scope1\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_scope\n'
            'package:tests/test.dart:13:16\n'
            '   ╷\n'
            '13 │ abstract class MySubcomponent {}\n'
            '   │                ^^^^^^^^^^^^^^\n'
            '   ╵',
          );
        },
      );
    });

    test('should failed if component build method return not subcomponent',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  @subcomponentFactory
  MyComponent createMyComponent();
}

abstract class MyComponent {}

        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: wrong_subcomponent_factory:\n'
            'Factory method AppComponent.createMyComponent must return subcomponent type.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#wrong_subcomponent_factory\n'
            'package:tests/test.dart:6:15\n'
            '  ╷\n'
            '6 │   MyComponent createMyComponent();\n'
            '  │               ^^^^^^^^^^^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test(
        'should fail if the component factory method has a non-builder parameter',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  @subcomponentFactory
  MyComponent createMyComponent(String builder);
}

@Subcomponent(
  builder: MyComponentBuilder,
)
abstract class MyComponent {}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponent build();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: invalid_subcomponent_factory:\n'
            'Class String must be annotated with @componentBuilder annotation.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_subcomponent_factory\n'
            'package:tests/test.dart:6:40\n'
            '  ╷\n'
            '6 │   MyComponent createMyComponent(String builder);\n'
            '  │                                        ^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('should fail if the component build method with multiple parameters',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  @subcomponentFactory
  MyComponent createMyComponent(String s1, String s2);
}

@Subcomponent(
  builder: MyComponentBuilder,
)
abstract class MyComponent {}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponent build();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: invalid_subcomponent_factory:\n'
            'Subcomponent factory method must have 1 parameter. And it should be a subcomponent builder\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_subcomponent_factory\n'
            'package:tests/test.dart:6:15\n'
            '  ╷\n'
            '6 │   MyComponent createMyComponent(String s1, String s2);\n'
            '  │               ^^^^^^^^^^^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test(
        'should fail if the component build method return different type than method.',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  builder: AppComponentBuilder,
)
abstract class AppComponent {
  @subcomponentFactory
  MyComponent createMyComponent(AppComponentBuilder builder);
}

@componentBuilder
abstract class AppComponentBuilder {
  AppComponent build();
}

@Subcomponent(
  builder: MyComponentBuilder,
)
abstract class MyComponent {}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponent build();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: wrong_subcomponent_factory:\n'
            'Subcomponent builder must return the same type as the method.\n'
            'Method return: MyComponent,\n'
            'Builder return: AppComponent.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#wrong_subcomponent_factory\n'
            'package:tests/test.dart:8:15\n'
            '  ╷\n'
            '8 │   MyComponent createMyComponent(AppComponentBuilder builder);\n'
            '  │               ^^^^^^^^^^^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('should fail if the component build method with nullable parameter',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  @subcomponentFactory
  MyComponent createMyComponent(MyComponentBuilder? builder);
}

@Subcomponent(
  builder: MyComponentBuilder,
)
abstract class MyComponent {
}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponent build();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: wrong_subcomponent_factory:\n'
            'Method AppComponent.createMyComponent is invalid. Nullable parameter not allowed.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#wrong_subcomponent_factory\n'
            'package:tests/test.dart:6:53\n'
            '  ╷\n'
            '6 │   MyComponent createMyComponent(MyComponentBuilder? builder);\n'
            '  │                                                     ^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('should fail if the component build method with named parameter',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  @subcomponentFactory
  MyComponent createMyComponent({required MyComponentBuilder builder});
}

@Subcomponent(
  builder: MyComponentBuilder,
)
abstract class MyComponent {
}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponent build();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: wrong_subcomponent_factory:\n'
            'Method AppComponent.createMyComponent is invalid. Named parameter not allowed.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#wrong_subcomponent_factory\n'
            'package:tests/test.dart:6:62\n'
            '  ╷\n'
            '6 │   MyComponent createMyComponent({required MyComponentBuilder builder});\n'
            '  │                                                              ^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('should fail if the component build method with optional parameter',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  @subcomponentFactory
  MyComponent createMyComponent([MyComponentBuilder? builder]);
}

@Subcomponent(
  builder: MyComponentBuilder,
)
abstract class MyComponent {
}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponent build();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: wrong_subcomponent_factory:\n'
            'Method AppComponent.createMyComponent is invalid. Optional parameter not allowed.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#wrong_subcomponent_factory\n'
            'package:tests/test.dart:6:54\n'
            '  ╷\n'
            '6 │   MyComponent createMyComponent([MyComponentBuilder? builder]);\n'
            '  │                                                      ^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('should fail if object provided in parent component and subcomponent',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';
import 'package:tests/util/scopes.dart';

@Component(modules: <Type>[MyComponentModule])
@scope1
abstract class MyComponent {
  @subcomponentFactory
  MySubcomponent createMyComponent();
}

@module
abstract class MyComponentModule {
  @provides
  static String provideString() => "";
}

@Subcomponent(
  modules: <Type>[MySubcomponentModule],
)
@scope2
abstract class MySubcomponent {
  String get string;
}

@module
abstract class MySubcomponentModule {
  @provides
  static String provideString() => "";
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: multiple_providers_for_type:\n'
            'String provided multiple times: MyComponentModule.provideString(MyComponent), MySubcomponentModule.provideString\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#multiple_providers_for_type',
          );
        },
      );
    });
  });

  group('custom scope', () {
    test(
        'should failed if component uscoped, but provider of module with scope',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String get string;
}

@module
abstract class AppModule {
  @provides
  @myScope
  static String provideString() => 'Hello';
}

@scope
class MyScope {
  const MyScope._();
}

const MyScope myScope = MyScope._();
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: invalid_scope:\n'
            'AppComponent (unscoped) may not use scoped bindings: MyScope(AppModule.provideString)\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_scope',
          );
        },
      );
    });

    test(
        'should failed if component and provider of module with different scopes',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
@singleton
abstract class AppComponent {
  String get string;
}

@module
abstract class AppModule {
  @provides
  @myScope
  static String provideString() => 'Hello';
}

@scope
class MyScope {
  const MyScope._();
}

const MyScope myScope = MyScope._();
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: invalid_scope:\n'
            'AppComponent (scoped Singleton) may not use scoped bindings: MyScope(AppModule.provideString)\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_scope',
          );
        },
      );
    });

    test(
        'should failed if component unscoped, but multiple providers of module with different scopes',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String get string;
  int get i;
}

@module
abstract class AppModule {
  @provides
  @myScope
  static String provideString() => 'Hello';

  @provides
  @singleton
  static int provideInt() => 0;
}

@scope
class MyScope {
  const MyScope._();
}

const MyScope myScope = MyScope._();
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: invalid_scope:\n'
            'AppComponent (unscoped) may not use scoped bindings: MyScope(AppModule.provideString)\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_scope',
          );
        },
      );
    });

    test(
        'should failed if component scoped and multiple providers of module with different scopes',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
@myScope
abstract class AppComponent {
  String get string;
  int get i;
}

@module
abstract class AppModule {
  @provides
  @myScope
  static String provideString() => 'Hello';

  @provides
  @singleton
  static int provideInt() => 0;
}

@scope
class MyScope {
  const MyScope._();
}

const MyScope myScope = MyScope._();
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: invalid_scope:\n'
            'AppComponent (scoped MyScope) may not use scoped bindings: Singleton(AppModule.provideInt)\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_scope',
          );
        },
      );
    });
  });

  group('Component as dependency', () {
    test('should failed if component builder not found', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

class AppConfig {
  AppConfig(this.hello);

  final String hello;
}

@Component(modules: <Type>[AppModule])
@singleton
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
            'error: missing_component_builder:\n'
            'Component MyComponent depends on AppComponent, but component builder is missing.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_component_builder\n'
            'package:tests/test.dart:26:16\n'
            '   ╷\n'
            '26 │ abstract class MyComponent {\n'
            '   │                ^^^^^^^^^^^\n'
            '   ╵',
          );
        },
      );
    });

    test('should failed if build method not found', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

class AppConfig {
  AppConfig(this.hello);

  final String hello;
}

@Component(modules: <Type>[AppModule])
@singleton
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
  builder: MyComponentBuilder,
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
            'Missing required build method of MyComponentBuilder package:tests/test.dart\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_build_method\n'
            'package:tests/test.dart:32:16\n'
            '   ╷\n'
            '32 │ abstract class MyComponentBuilder {\n'
            '   │                ^^^^^^^^^^^^^^^^^^\n'
            '   ╵',
          );
        },
      );
    });

    test('should failed if build method return not component type', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

class AppConfig {
  AppConfig(this.hello);

  final String hello;
}

@Component(
  modules: <Type>[AppModule],
  builder: AppComponentBuilder,
)
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
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#wrong_type_of_build_method\n'
            'package:tests/test.dart:36:23\n'
            '   ╷\n'
            '36 │   AppComponentBuilder build();\n'
            '   │                       ^^^^^\n'
            '   ╵',
          );
        },
      );
    });

    test('should failed if object not provided by build method', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

class AppConfig {
  AppConfig(this.hello);

  final String hello;
}

@Component(modules: <Type>[AppModule])
@singleton
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
  builder: MyComponentBuilder
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
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_component_dependency\n'
            'package:tests/test.dart:32:16\n'
            '   ╷\n'
            '32 │ abstract class MyComponentBuilder {\n'
            '   │                ^^^^^^^^^^^^^^^^^^\n'
            '   ╵',
          );
        },
      );
    });

    test(
        'should failed if object provided multiple time from parent component and module',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

class AppConfig {
  AppConfig(this.hello);

  final String hello;
}

@Component(modules: <Type>[AppModule])
@singleton
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
  builder: MyComponentBuilder,
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
            'error: multiple_providers_for_type:\n'
            'AppConfig provided multiple times: AppComponent.appConfig, MyModule.provideAppConfig\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#multiple_providers_for_type',
          );
        },
      );
    });

    test('should failed if object provided multiple time from same module',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String get string;
}

@module
abstract class AppModule {
  @provides
  static String provideString1() => '';

  @provides
  static String provideString2() => '';
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: multiple_providers_for_type:\n'
            'String provided multiple times: AppModule.provideString1, AppModule.provideString2\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#multiple_providers_for_type',
          );
        },
      );
    });

    test(
        'should failed if object provided multiple time from different modules',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule1, AppModule2])
abstract class AppComponent {
  String get string;
}

@module
abstract class AppModule1 {
  @provides
  static String provideString2() => '';
}

@module
abstract class AppModule2 {
  @provides
  static String provideString1() => '';
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: multiple_providers_for_type:\n'
            'String provided multiple times: AppModule1.provideString2, AppModule2.provideString1\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#multiple_providers_for_type',
          );
        },
      );
    });

    test('should failed if object provided from module and included module',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule1])
abstract class AppComponent {
  String get string;
}

@Module(includes: <Type>[AppModule2])
abstract class AppModule1 {
  @provides
  static String provideString2() => '';
}

@module
abstract class AppModule2 {
  @provides
  static String provideString1() => '';
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: multiple_providers_for_type:\n'
            'String provided multiple times: AppModule2.provideString1, AppModule1.provideString2\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#multiple_providers_for_type',
          );
        },
      );
    });

    test('should failed if object provided from args and module', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[AppModule1],
  builder: AppComponentBuilder,
)
abstract class AppComponent {
  String get string;
}

@module
abstract class AppModule1 {
  @provides
  static String provideString2() => '';
}

@componentBuilder
abstract class AppComponentBuilder {
  AppComponentBuilder setString(String s);

  AppComponent build();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: multiple_providers_for_type:\n'
            'String provided multiple times: AppModule1.provideString2, AppComponentBuilder.setString\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#multiple_providers_for_type',
          );
        },
      );
    });

    test('should failed if object provided from args and included module',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[AppModule1],
  builder: AppComponentBuilder,
  )
abstract class AppComponent {
  String get string;
}

@Module(includes: <Type>[AppModule2])
abstract class AppModule1 {}

@module
abstract class AppModule2 {
  @provides
  static String provideString2() => '';
}

@componentBuilder
abstract class AppComponentBuilder {
  AppComponentBuilder setString(String s);

  AppComponent build();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: multiple_providers_for_type:\n'
            'String provided multiple times: AppModule2.provideString2, AppComponentBuilder.setString\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#multiple_providers_for_type',
          );
        },
      );
    });

    test('should failed if object provided from parent component and module',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String get string;
}

@module
abstract class AppModule {
  @provides
  static String provideString() => '';
}

@Component(
  dependencies: <Type>[AppComponent],
  modules: <Type>[MyModule],
  builder: MyComponentBuilder,
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
  static String provideHelloString() => '';
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: multiple_providers_for_type:\n'
            'String provided multiple times: AppComponent.string, MyModule.provideHelloString\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#multiple_providers_for_type',
          );
        },
      );
    });
  });

  group('build config', () {
    test('should failed if found unused providers', () async {
      await checkBuilderResult(
        mainContent: '''
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
            'error: unused_generated_providers:\n'
            'Found unused generated providers: _string0Provider\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#unused_generated_providers',
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
      await checkBuilderResult(
        mainContent: '''
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
            'error: provider_not_found:\n'
            'Provider for String with qualifier my not found.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#provider_not_found',
          );
        },
      );
    });

    test('should failed if qualifier not found', () async {
      await checkBuilderResult(
        mainContent: '''
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
            'error: provider_not_found:\n'
            'Provider for String with qualifier My not found.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#provider_not_found',
          );
        },
      );
    });

    test('should failed if multiple qualifiers', () async {
      await checkBuilderResult(
        mainContent: '''
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
            'error: multiple_qualifiers:\n'
            'Multiple qualifiers of AppComponent.appConfig not allowed.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#multiple_qualifiers\n'
            'package:tests/test.dart:9:17\n'
            '  ╷\n'
            '9 │   AppConfig get appConfig;\n'
            '  │                 ^^^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });
  });

  group('injectable field', () {
    test('private injectable field', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

class InjectableClass {
  @inject
  late String _helloString;
}

@Component(modules: <Type>[AppModule])
@singleton
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
            'error: Field _helloString must be only public.\n'
            'package:tests/test.dart:5:15\n'
            '  ╷\n'
            '5 │   late String _helloString;\n'
            '  │               ^^^^^^^^^^^^\n'
            '  ╵',
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
      await checkBuilderResult(
        mainContent: '''
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
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#bind_wrong_type\n'
            'package:tests/test.dart:9:11\n'
            '  ╷\n'
            '9 │   Pattern bindPattern(int impl);\n'
            '  │           ^^^^^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('bind method with multiple parameters', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String getString();
}

@module
abstract class AppModule {
  @binds
  String bindString(String s, int i);
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: invalid_bind_method:\n'
            'Method AppModule.bindString annotated with Binds must have one parameter.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_bind_method\n'
            'package:tests/test.dart:11:10\n'
            '   ╷\n'
            '11 │   String bindString(String s, int i);\n'
            '   │          ^^^^^^^^^^\n'
            '   ╵',
          );
        },
      );
    });

    test('binds class without injected constructor', () async {
      await checkBuilderResult(
        mainContent: '''
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
            'error: missing_injected_constructor:\n'
            'Class MainRouter cannot be provided without an @inject constructor.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_injected_constructor\n'
            'The following entry points depend on MainRouter:\n'
            'AppModule.bindMainRouter(MainRouter impl)',
          );
        },
      );
    });
  });

  group('unsupported type', () {
    test('nullable component getter with String type', () async {
      await checkBuilderResult(
        mainContent: '''
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

    test('nullable parameter in injected constructor', () async {
      await checkBuilderResult(
        mainContent: '''
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

    test('provider method return nullable type', () async {
      await checkBuilderResult(
        mainContent: '''
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

    test('nullable parameter in provide method', () async {
      await checkBuilderResult(
        mainContent: '''
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

    test('build instance nullable type', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  builder: MyComponentBuilder,
)
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

    test('binds nullable type', () async {
      await checkBuilderResult(
        mainContent: '''
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
      await checkBuilderResult(
        mainContent: '''
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

    test('unsupported type in generic type', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[MyModule])
abstract class MyComponent {
  dynamic get myDynamic;
}

@module
abstract class MyModule {
  @provides
  static dynamic provideMyDynamic() async => '';
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: type_not_supported:\n'
            'Type dynamic not supported.\n'
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
    test(
      'invalid member in module',
      () async {
        await checkBuilderResult(
          mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String getName();
}

@module
abstract class AppModule {
  @provides
  static String provideName() => 'hello';

  static int get staticGetter => 1;
}
        ''',
          onError: (Object error) {
            expect(
              error.toString(),
              'error: invalid_member:\n'
              'Unsupported member staticGetter in Module.\n'
              'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_member',
            );
          },
        );
      },
    );

    test('abstract method without bind annotation', () async {
      await checkBuilderResult(
        mainContent: '''
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
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_bind_annotation\n'
            'package:tests/test.dart:8:11\n'
            '  ╷\n'
            '8 │   Pattern bindPattern(String impl);\n'
            '  │           ^^^^^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('public module', () async {
      await checkBuilderResult(
        mainContent: '''
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
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#public_module\n'
            'package:tests/test.dart:7:16\n'
            '  ╷\n'
            '7 │ abstract class _Module {}\n'
            '  │                ^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('abstract module', () async {
      await checkBuilderResult(
        mainContent: '''
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
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#abstract_module\n'
            'package:tests/test.dart:7:7\n'
            '  ╷\n'
            '7 │ class Module {}\n'
            '  │       ^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('module annotation required', () async {
      await checkBuilderResult(
        mainContent: '''
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
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#module_annotation_required\n'
            'package:tests/test.dart:6:16\n'
            '  ╷\n'
            '6 │ abstract class Module {}\n'
            '  │                ^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('static method without provide annotation', () async {
      await checkBuilderResult(
        mainContent: '''
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
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_provides_annotation\n'
            'package:tests/test.dart:8:17\n'
            '  ╷\n'
            '8 │   static String provideString() => \'\';\n'
            '  │                 ^^^^^^^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('abstract or static method', () async {
      await checkBuilderResult(
        mainContent: '''
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
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#unsupported_method_type\n'
            'package:tests/test.dart:9:10\n'
            '  ╷\n'
            '9 │   String providerString() => \'\';\n'
            '  │          ^^^^^^^^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('private method', () async {
      await checkBuilderResult(
        mainContent: '''
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
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#private_method_of_module\n'
            'package:tests/test.dart:9:17\n'
            '  ╷\n'
            '9 │   static String _providerString() => \'\';\n'
            '  │                 ^^^^^^^^^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('binds and provides together', () async {
      await checkBuilderResult(
        mainContent: '''
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
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#ambiguity_of_provide_method\n'
            'package:tests/test.dart:10:11\n'
            '   ╷\n'
            '10 │   Pattern bindPattern(String impl);\n'
            '   │           ^^^^^^^^^^^\n'
            '   ╵',
          );
        },
      );
    });

    test('provides nullable type', () async {
      await checkBuilderResult(
        mainContent: '''
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
      'The specified builder is not suitable for the component',
      () async {
        await checkBuilderResult(
          mainContent: '''
import 'package:jugger/jugger.dart';

@Component(builder: MyComponentBuilder)
abstract class AppComponent {}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponent build();
}

@Component(builder: MyComponentBuilder)
abstract class MyComponent {}
        ''',
          onError: (Object error) {
            expect(
              error.toString(),
              'error: invalid_subcomponent_factory:\n'
              'The MyComponentBuilder is not suitable for the AppComponent it is bound to.\n'
              'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_subcomponent_factory\n'
              'package:tests/test.dart:7:16\n'
              '  ╷\n'
              '7 │ abstract class MyComponentBuilder {\n'
              '  │                ^^^^^^^^^^^^^^^^^^\n'
              '  ╵',
            );
          },
        );
      },
    );

    test(
      'The specified type is not component builder',
      () async {
        await checkBuilderResult(
          mainContent: '''
import 'package:jugger/jugger.dart';

@Component(builder: MyComponentBuilder)
abstract class AppComponent {}

abstract class MyComponentBuilder {
  AppComponent build();
}
        ''',
          onError: (Object error) {
            expect(
              error.toString(),
              'error: wrong_component_builder:\n'
              'MyComponentBuilder is not component builder.\n'
              'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#wrong_component_builder',
            );
          },
        );
      },
    );

    test(
      'invalid member in component',
      () async {
        await checkBuilderResult(
          mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  set setter(bool value);
}
        ''',
          onError: (Object error) {
            expect(
              error.toString(),
              'error: invalid_member:\n'
              'Unsupported member setter= in Component.\n'
              'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_member\n'
              'package:tests/test.dart:5:7\n'
              '  ╷\n'
              '5 │   set setter(bool value);\n'
              '  │       ^^^^^^\n'
              '  ╵',
            );
          },
        );
      },
    );

    test(
      'invalid member in component builder',
      () async {
        await checkBuilderResult(
          mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  builder: MyComponentBuilder,
)
abstract class AppComponent {
  String get string;
}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponentBuilder appComponent(String s);

  int get getter => 1;

  AppComponent build();
}
        ''',
          onError: (Object error) {
            expect(
              error.toString(),
              'error: invalid_member:\n'
              'Unsupported member getter in ComponentBuilder.\n'
              'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_member',
            );
          },
        );
      },
    );

    test(
      'Component should only have abstract classes as ancestor.',
      () async {
        await checkBuilderResult(
          mainContent: '''
import 'package:jugger/jugger.dart';

class Ancestor1 {}

@Component(modules: <Type>[Module1])
abstract class AppComponent extends Ancestor1 {
  String getString1();
}

@module
abstract class Module1 {
  @provides
  static String provideString() => 's';
}
        ''',
          onError: (Object error) {
            expect(
              error.toString(),
              'error: invalid_component:\n'
              'Component AppComponent should only have abstract classes as ancestor.\n'
              'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_component\n'
              'package:tests/test.dart:6:16\n'
              '  ╷\n'
              '6 │ abstract class AppComponent extends Ancestor1 {\n'
              '  │                ^^^^^^^^^^^^\n'
              '  ╵',
            );
          },
        );
      },
    );

    test(
      'injectable method without one parameter',
      () async {
        await checkBuilderResult(
          mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  void inject(int i, String s);
}
        ''',
          onError: (Object error) {
            expect(
              error.toString(),
              'error: invalid_injectable_method:\n'
              'Injected method inject must have one parameter.\n'
              'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_injectable_method\n'
              'package:tests/test.dart:5:8\n'
              '  ╷\n'
              '5 │   void inject(int i, String s);\n'
              '  │        ^^^^^^\n'
              '  ╵',
            );
          },
        );
      },
    );

    test(
      'should fail if method not abstract',
      () async {
        await checkBuilderResult(
          mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  String getString() => '';
}
        ''',
          onError: (Object error) {
            expect(
              error.toString(),
              'error: invalid_method_of_component:\n'
              'Method getString of component must be abstract.\n'
              'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_method_of_component\n'
              'package:tests/test.dart:5:10\n'
              '  ╷\n'
              '5 │   String getString() => \'\';\n'
              '  │          ^^^^^^^^^\n'
              '  ╵',
            );
          },
        );
      },
    );

    test(
      'should fail if method not public',
      () async {
        await checkBuilderResult(
          mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  String _getString();
}
        ''',
          onError: (Object error) {
            expect(
              error.toString(),
              'error: invalid_method_of_component:\n'
              'Method _getString of component must be public.\n'
              'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_method_of_component\n'
              'package:tests/test.dart:5:10\n'
              '  ╷\n'
              '5 │   String _getString();\n'
              '  │          ^^^^^^^^^^\n'
              '  ╵',
            );
          },
        );
      },
    );

    test(
      'should fail if method with parameters',
      () async {
        await checkBuilderResult(
          mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  String getString(String s);
}
        ''',
          onError: (Object error) {
            expect(
              error.toString(),
              'error: invalid_method_of_component:\n'
              'Method getString of component must have zero parameters.\n'
              'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_method_of_component\n'
              'package:tests/test.dart:5:10\n'
              '  ╷\n'
              '5 │   String getString(String s);\n'
              '  │          ^^^^^^^^^\n'
              '  ╵',
            );
          },
        );
      },
    );

    test(
      'should fail if class with qualifier, but constructor is injected',
      () async {
        await checkBuilderResult(
          mainContent: '''
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
              'error: provider_not_found:\n'
              'Provider for MyClass with qualifier test not found.\n'
              'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#provider_not_found',
            );
          },
        );
      },
    );

    test('repeated modules', () async {
      await checkBuilderResult(
        mainContent: '''
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
      await checkBuilderResult(
        mainContent: '''
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

    test('final component', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract final class MyComponent { }
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: final_component:\n'
            'Component MyComponent cannot be final.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#final_component\n'
            'package:tests/test.dart:4:22\n'
            '  ╷\n'
            '4 │ abstract final class MyComponent { }\n'
            '  │                      ^^^^^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('base component', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract base class MyComponent { }
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: base_component:\n'
            'Component MyComponent cannot be base.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#base_component\n'
            'package:tests/test.dart:4:21\n'
            '  ╷\n'
            '4 │ abstract base class MyComponent { }\n'
            '  │                     ^^^^^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('sealed component', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
sealed class MyComponent { }
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: base_component:\n'
            'Component MyComponent cannot be sealed.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#base_component\n'
            'package:tests/test.dart:4:14\n'
            '  ╷\n'
            '4 │ sealed class MyComponent { }\n'
            '  │              ^^^^^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('final component builder', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(builder: MyComponentBuilder)
abstract class MyComponent {}

@componentBuilder
abstract final class MyComponentBuilder {
  MyComponent build();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: final_component_builder:\n'
            'Component builder MyComponentBuilder cannot be final.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#final_component_builder\n'
            'package:tests/test.dart:7:22\n'
            '  ╷\n'
            '7 │ abstract final class MyComponentBuilder {\n'
            '  │                      ^^^^^^^^^^^^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('base component builder', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(builder: MyComponentBuilder)
abstract class MyComponent {}

@componentBuilder
abstract base class MyComponentBuilder {
  MyComponent build();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: base_component_builder:\n'
            'Component builder MyComponentBuilder cannot be base.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#base_component_builder\n'
            'package:tests/test.dart:7:21\n'
            '  ╷\n'
            '7 │ abstract base class MyComponentBuilder {\n'
            '  │                     ^^^^^^^^^^^^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('sealed component builder', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(builder: MyComponentBuilder)
abstract class MyComponent {}

@componentBuilder
sealed class MyComponentBuilder {
  MyComponent build();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: sealed_component_builder:\n'
            'Component builder MyComponentBuilder cannot be sealed.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#sealed_component_builder\n'
            'package:tests/test.dart:7:14\n'
            '  ╷\n'
            '7 │ sealed class MyComponentBuilder {\n'
            '  │              ^^^^^^^^^^^^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('public component', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[])
abstract class _Component {}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: public_component:\n'
            'Component _Component must be public.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#public_component\n'
            'package:tests/test.dart:4:16\n'
            '  ╷\n'
            '4 │ abstract class _Component {}\n'
            '  │                ^^^^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('abstract component', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
class AppComponent {}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: abstract_component:\n'
            'Component AppComponent must be abstract.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#abstract_component\n'
            'package:tests/test.dart:4:7\n'
            '  ╷\n'
            '4 │ class AppComponent {}\n'
            '  │       ^^^^^^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('not component a dependency', () async {
      await checkBuilderResult(
        mainContent: '''
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
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(dependencies: <Type>[AppComponent])
abstract class AppComponent {}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: component_depend_himself:\n'
            'A component AppComponent cannot depend on himself.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#component_depend_himself\n'
            'package:tests/test.dart:4:16\n'
            '  ╷\n'
            '4 │ abstract class AppComponent {}\n'
            '  │                ^^^^^^^^^^^^\n'
            '  ╵',
          );
        },
      );
    });

    test('public component builder', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  modules: <Type>[],
  builder: _MyComponentBuilder,
)
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
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#public_component_builder\n'
            'package:tests/test.dart:10:16\n'
            '   ╷\n'
            '10 │ abstract class _MyComponentBuilder {\n'
            '   │                ^^^^^^^^^^^^^^^^^^^\n'
            '   ╵',
          );
        },
      );
    });

    test('component builder invalid method type', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  builder: ComponentBuilder,
)
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
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#component_builder_invalid_method_type\n'
            'package:tests/test.dart:10:16\n'
            '   ╷\n'
            '10 │   AppComponent setInt(int i);\n'
            '   │                ^^^^^^\n'
            '   ╵',
          );
        },
      );
    });

    test('wrong arguments of build method', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  builder: ComponentBuilder,
)
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
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#wrong_arguments_of_build_method\n'
            'package:tests/test.dart:10:16\n'
            '   ╷\n'
            '10 │   AppComponent build(int i);\n'
            '   │                ^^^^^\n'
            '   ╵',
          );
        },
      );
    });

    test('component builder type provided multiple times', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  builder: MyComponentBuilder,
)
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
            'error: multiple_providers_for_type:\n'
            'String provided multiple times: MyComponentBuilder.setString, MyComponentBuilder.setString2\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#multiple_providers_for_type',
          );
        },
      );
    });

    test('component builder method must be public', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(
  builder: MyComponentBuilder,
)
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
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#component_builder_private_method\n'
            'package:tests/test.dart:12:22\n'
            '   ╷\n'
            '12 │   MyComponentBuilder _setString(String s);\n'
            '   │                      ^^^^^^^^^^\n'
            '   ╵',
          );
        },
      );
    });
  });

  group('injected method', () {
    test('private method', () async {
      await checkBuilderResult(
        mainContent: '''
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
  void _init(int i) {}
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: invalid_injected_method:\n'
            'Injected method _init must be public.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_injected_method\n'
            'package:tests/test.dart:19:8\n'
            '   ╷\n'
            '19 │   void _init(int i) {}\n'
            '   │        ^^^^^\n'
            '   ╵',
          );
        },
      );
    });

    test('static method', () async {
      await checkBuilderResult(
        mainContent: '''
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
            'error: invalid_injected_method:\n'
            'Injected method init can not be static.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_injected_method\n'
            'package:tests/test.dart:19:15\n'
            '   ╷\n'
            '19 │   static void init(int i) {}\n'
            '   │               ^^^^\n'
            '   ╵',
          );
        },
      );
    });

    test('abstract method', () async {
      await checkBuilderResult(
        mainContent: '''
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
            'error: invalid_injected_method:\n'
            'Injected method init can not be abstract.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#invalid_injected_method\n'
            'package:tests/test.dart:26:8\n'
            '   ╷\n'
            '26 │   void init(int i);\n'
            '   │        ^^^^\n'
            '   ╵',
          );
        },
      );
    });
  });

  group('lazy', () {
    test('missing lazy of type for module method arg 2', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String getString();
}

@module
abstract class AppModule {
  @provides
  static String provideString(ILazy<int> i) => '';
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: provider_not_found:\n'
            'Provider for int not found.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#provider_not_found',
          );
        },
      );
    });

    test('missing lazy of type with qualifier for module method arg 2',
        () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String getString();
}

@module
abstract class AppModule {
  @provides
  static String provideString(@Named('i') ILazy<int> i) => '';
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: provider_not_found:\n'
            'Provider for int with qualifier i not found.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#provider_not_found',
          );
        },
      );
    });
  });

  group('entry points', () {
    test('bind method of module entry point', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  MyClass get myClass;
}

@module
abstract class AppModule {
  @binds
  MyClass bindMyClass(MyClassImpl impl);
}

abstract class MyClass {}

class MyClassImpl implements MyClass {}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: missing_injected_constructor:\n'
            'Class MyClassImpl cannot be provided without an @inject constructor.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_injected_constructor\n'
            'The following entry points depend on MyClassImpl:\n'
            'AppModule.bindMyClass(MyClassImpl impl)',
          );
        },
      );
    });
    test('bind method of module entry point with qualifier', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  MyClass get myClass;
}

@module
abstract class AppModule {
  @binds
  MyClass bindMyClass(@Named('my') MyClassImpl impl);
}

abstract class MyClass {}

class MyClassImpl implements MyClass {}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: provider_not_found:\n'
            'Provider for MyClassImpl with qualifier my not found.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#provider_not_found\n'
            'The following entry points depend on MyClassImpl:\n'
            'AppModule.bindMyClass(@my MyClassImpl impl)',
          );
        },
      );
    });
    test('constructor entry point', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  MyClass get myClass;
}

class MyClass {
  @inject
  const MyClass(this.myClass2);

  final MyClass2 myClass2;
}

class MyClass2 {
  const MyClass2();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: missing_injected_constructor:\n'
            'Class MyClass2 cannot be provided without an @inject constructor.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_injected_constructor\n'
            'The following entry points depend on MyClass2:\n'
            'MyClass(MyClass2 myClass2)',
          );
        },
      );
    });
    test('constructor entry point with qualifier', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  MyClass get myClass;
}

class MyClass {
  @inject
  const MyClass(@Named('my') this.myClass2);

  final MyClass2 myClass2;
}

class MyClass2 {
  const MyClass2();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: provider_not_found:\n'
            'Provider for MyClass2 with qualifier my not found.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#provider_not_found\n'
            'The following entry points depend on MyClass2:\n'
            'MyClass(@my MyClass2 myClass2)',
          );
        },
      );
    });
    test('provide method of module entry point', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String get string;
}

@module
abstract class AppModule {
  @provides
  static String provideString(MyClass myClass) => myClass.toString();
}

class MyClass {
  const MyClass();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: missing_injected_constructor:\n'
            'Class MyClass cannot be provided without an @inject constructor.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#missing_injected_constructor\n'
            'The following entry points depend on MyClass:\n'
            'AppModule.provideString(MyClass myClass)',
          );
        },
      );
    });
    test('provide method of module entry point with qualifier', () async {
      await checkBuilderResult(
        mainContent: '''
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  String get string;
}

@module
abstract class AppModule {
  @provides
  static String provideString(@Named('my') MyClass myClass) =>
      myClass.toString();
}

class MyClass {
  const MyClass();
}
        ''',
        onError: (Object error) {
          expect(
            error.toString(),
            'error: provider_not_found:\n'
            'Provider for MyClass with qualifier my not found.\n'
            'Explanation of Error: https://github.com/ivk1800/jugger.dart/blob/master/jugger_generator/GLOSSARY_OF_ERRORS.md#provider_not_found\n'
            'The following entry points depend on MyClass:\n'
            'AppModule.provideString(@my MyClass myClass)',
          );
        },
      );
    });
  });
}
