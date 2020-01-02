## jugger.dart - Dependency Injection for Flutter and Dart

jugger:

[![pub package](https://img.shields.io/pub/v/jugger.svg?style=plastic&logo=appveyor)](https://pub.dartlang.org/packages/jugger)

jugger_generator:

[![pub package](https://img.shields.io/pub/v/jugger_generator.svg?style=plastic&logo=appveyor)](https://pub.dartlang.org/packages/jugger_generator)


Compile-time dependency injection for Dart and Flutter.

Android developers will easily understand the use of the library, jagger similar [Dagger2](https://github.com/google/dagger)

#### Getting Started

In your flutter or dart project add the dependency:

```yml
dependencies:
  ...
  jugger: any

dev_dependencies:
  ...
  build_runner: any
  dev_dependencies: any
```

#### Usage example
Define your component and module for the dependency provider, it is recommended to do this in a separate file:
```dart
import 'package:jugger/jugger.dart';

import 'main.dart';

@Component([MyModule])
abstract class MyComponent {
  ///
  /// inject default page state from new flutter project
  /// 
  void injectMyHomePageState(MyHomePageState target);
}

@module
abstract class MyModule {
  static String provideString() {
    return 'hello';
  }
}
```

Declare variable and annotate its with @inject:
```dart
...
class MyHomePageState extends State<MyHomePage> {

  @inject
  String injectedString;
...
```

Now you need to execute the command
```
flutter packages pub run build_runner build
```
A file with the implemented component will be generated, for example ```inject.jugger.dart```

Now you need to directly inject your class:
```dart
...
import 'inject.jugger.dart';
...

...
  @override
  void initState() {
    JuggerMyComponent myComponent = JuggerMyComponent.create();
    myComponent.injectMyHomePageState(this);
    super.initState();
  }
...

```

#### Limitations:
not allowed inject Functions, example:
```dart
typedef Click<T> = void Function(T result); 
```

#### SubComponents:
example:
```dart
@Component(
    modules: <Type>[RegisterScreenModule], dependencies: <Type>[AppComponent])
abstract class RegisterScreenComponent {
  void inject(RegisterPageState target);
}

@componentBuilder
abstract class RegisterScreenComponentBuilder {
  RegisterScreenComponentBuilder appComponent(AppComponent component);

  RegisterScreenComponentBuilder screen(RegisterPageState screen);

  RegisterScreenComponent build();
}

@module
abstract class RegisterScreenModule {
  @provide
  static ResultDispatcher<UserCredentials> provideResultDispatcher(
      RegisterPageState screen) {
    return screen;
  }
}

extension RegisterScreenInject on RegisterPageState {
  void inject() {
        JuggerRegisterScreenComponentBuilder()
            .screen(this)
            .appComponent(appComponent)
            .build().inject(this);
  }
}
```

#### Annotations
| Name | Description |
|---|---|
|  @Component |  TODO | 
| @Module  |  TODO |
|  @Singleton | TODO  |
|  @Provide | TODO  |
|  @Inject |  TODO |
|  @Bind |  TODO |
|  @ComponentBuilder |  TODO |
|  @Named |  TODO |

#### Powerful example
In this repo you can find Best practice [example1](examples/example1) of jugger with multiple dependencies and using all annotations.

#### Bugs
the library is in alpha version, if you find a bug, you can create a [issue](https://github.com/ivk1800/jugger.dart/issues/new)

#### Contributions
Contributions are welcome!

If you fixed a bug or implemented a new feature, please send a pull [request](https://github.com/ivk1800/jugger.dart/pulls).