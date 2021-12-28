## jugger.dart - Dependency Injection for Flutter and Dart

jugger:

[![pub package](https://img.shields.io/pub/v/jugger.svg?style=plastic&logo=appveyor)](https://pub.dartlang.org/packages/jugger)

jugger_generator:

[![pub package](https://img.shields.io/pub/v/jugger_generator.svg?style=plastic&logo=appveyor)](https://pub.dartlang.org/packages/jugger_generator)


Compile-time dependency injection for Dart and Flutter.

Android developers will easily understand the use of the library, jugger similar [Dagger2](https://github.com/google/dagger)

#### Getting Started

In your flutter or dart project add the dependency:

```yml
dependencies:
  jugger: any

dev_dependencies:
  build_runner: any
  dev_dependencies: any
```

#### Usage example
Define your component and module for the dependency provider, it is recommended to do this in a separate file:
```dart
// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(modules: <Type>[MyModule])
abstract class MyComponent {
  String get helloString;

  String getHelloString();
}

@module
abstract class MyModule {
  @provide
  static String provideString() {
    return 'hello';
  }
}
```

Now you need to execute the command
```
flutter packages pub run build_runner build
```
or for dart
```
dart run build_runner build --delete-conflicting-outputs
```

A file with the implemented component will be generated, for example ```main.jugger.dart```

And use component as:
```dart
void main() {
  final MyComponent myComponent = JuggerMyComponent.create();
  print(myComponent.helloString);
  print(myComponent.getHelloString());
}
```

#### SubComponents:
example:
```dart
// ignore_for_file: avoid_classes_with_only_static_members

import 'package:jugger/jugger.dart';

@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  int get appVersion;
}

@module
abstract class AppModule {
  @provide
  static int provideAppVersion() => 1;
}

@Component(
  dependencies: <Type>[AppComponent],
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  String get myHelloString;
}

@module
abstract class MyModule {
  @provide
  static String provideMyHelloString(int appVersion) {
    return 'hello app with version: $appVersion';
  }
}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponentBuilder appComponent(AppComponent component);

  MyComponent build();
}

void main() {
  final AppComponent appComponent = JuggerAppComponent.create();

  final MyComponent myComponent =
  JuggerMyComponentBuilder().appComponent(appComponent).build();

  print(myComponent.myHelloString);
}
```

#### interface prefix:
If interface have prefix 'I' you can ignore his during generation:

build.yaml
```yaml
targets:
  $default:
    builders:
      jugger_generator:
        options:
          ignore_interface_prefix_in_component_name: false
```
```dart
@Component(modules: <Type>[AppModule])
abstract class IAppComponent {}
```
and use as:
```dart
var component = JuggerMyComponent.create();
```
instead:
```dart
var component = JuggerIMyComponent.create();
```

#### Bugs
If you find a bug, you can create a [issue](https://github.com/ivk1800/jugger.dart/issues/new)

#### Contributions
Contributions are welcome!

If you fixed a bug or implemented a new feature, please send a pull [request](https://github.com/ivk1800/jugger.dart/pulls).
