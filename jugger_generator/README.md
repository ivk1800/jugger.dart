## jugger.dart - Dependency Injection for Flutter and Dart

Compile-time dependency injection for Dart and Flutter. Inspired by [inject.dart](https://github.com/google/inject.dart) and [Dagger 2](https://github.com/google/dagger).

Jugger's feature is that it generates boilerplate code. You just need to provide dependencies and how they will be used in graph.

jugger:

[![pub package](https://img.shields.io/pub/v/jugger.svg?style=plastic&logo=appveyor)](https://pub.dartlang.org/packages/jugger)

jugger_generator:

[![pub package](https://img.shields.io/pub/v/jugger_generator.svg?style=plastic&logo=appveyor)](https://pub.dartlang.org/packages/jugger_generator)

# Index
- [Index](#index)
- [How to use](#how-to-use)
    - [Install](#install)
    - [Run the generator](#run-the-generator)
- [The features](#the-features)
    - [The syntax](#the-syntax)
        - [Basics](#basics)
        - [Component](#component)
        - [Subcomponents](#subcomponents)
            - [Declaring a subcomponent](#declaring-a-subcomponent)
            - [Adding a subcomponent to a parent component](#adding-a-subcomponent-to-a-parent-component)
            - [Subcomponents and scope](#subcomponents-and-scope)
            - [Subcomponent with builder](#subcomponent-with-builder)
        - [Component builder](#component-builder)
        - [Component as dependency](#component-as-dependency)
        - [Module](#module)
        - [Included modules](#included-modules)
        - [Provide method](#provide-method)
        - [Bind method](#bind-method)
        - [Singleton](#singleton)
        - [Inject](#inject)
        - [Injected constructor](#injected-constructor)
        - [Injected method](#injected-method)
        - [Qualifiers](#qualifiers)
        - [Disposable component](#disposable-component)
        - [Multibindings](#multibindings)
             - [Set multibindings](#set-multibindings)
             - [Map multibindings](#map-multibindings)
        - [Lazy initialization](#lazy-initialization)
    - [build.yaml](#buildyaml)
    - [remove_interface_prefix_from_component_name](#remove_interface_prefix_from_component_name)
    - [check_unused_providers](#check_unused_providers)
- [Migration](#migration)
    - [From 2.* to 3.*](#from-2-to-3)
        - [Scope related changes](#scope-related-changes)
        - [Component builder related changes](#component-builder-related-changes)
- [Links](#links)


# How to use

## Install
To use this plugin, add `jugger` and `jugger_generator` as a dependency in your pubspec.yaml file.
```yml
dependencies:
  jugger: any

dev_dependencies:
  build_runner: any
  jugger_generator: any
```

## Run the generator

To run the code generator you have two possibilities:

- If your package depends on Flutter:
    - `flutter pub run build_runner build`
- If your package _does not_ depend on Flutter:
    - `dart pub run build_runner build`

# The features

## The syntax

### Basics

The following example shows how to use jugger:

```dart
import 'package:example/main.jugger.dart';
import 'package:jugger/jugger.dart';

void main() {
  final MyComponent myComponent = JuggerMyComponent.create();
  print(myComponent.getString());
}

@Component(
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  String getString();
}

@module
abstract class MyModule {
  @provides
  static String provideSting() => 'hello!';
}
```

### Component
`Component` are connecting links between `Modules` and dependants. When we need some object we ask the Component. The Component knows which module can create the needed object and return it to the dependant.

A component can have `modules` and `other components` that it requests dependencies on:

```dart
@Component(
  modules: <Type>[...],
  dependencies: <Type>[...]
)
```

### Subcomponents

Subcomponents are components that inherit and extend the object graph of a parent component. You can use them to partition your application’s object graph into subgraphs either to encapsulate different parts of your application from each other.

#### Declaring a subcomponent

Just like for top-level components, you create a subcomponent by writing a class that declares abstract methods that return the types your application cares about. Instead of annotating a subcomponent with @Component, you annotate it with @Subcomponent and install @Modules.

```dart
@Subcomponent(
  modules: <Type>[MySubcomponentModule],
)
abstract class MySubcomponent {
  String getString();
}

@module
abstract class MySubcomponentModule {
  @provides
  static String provideString() => '';
}
```

#### Adding a subcomponent to a parent component

To add a subcomponent to a parent component, add a method that returns the type of the subcomponent. Don't forget to annotate method by @subcomponentFactory.

```dart
import 'package:jugger/jugger.dart';

@Component()
abstract class MyComponent {
  @subcomponentFactory
  MySubcomponent createMySubcomponent();
}
```

#### Subcomponents and scope

One reason to break your application's component up into subcomponents is to use scopes. With normal, unscoped bindings, each user of an injected type may get a new, separate instance. But if the binding is scoped, then all users of that binding within the scope's lifetime get the same instance of the bound type.

The standard scope is @singleton. Users of singleton-scoped bindings all get the same instance.

A Component can be associated with a scope by annotating it with a @scope annotation. In that case, the component implementation holds references to all scoped objects, so they can be reused. Modules with @provides methods annotated with a scope may only be installed into a component annotated with the same scope.

No subcomponent may be associated with the same scope as any ancestor component, although two subcomponents that are not mutually reachable can be associated with the same scope because there is no ambiguity about where to store the scoped objects. (The two subcomponents effectively have different scope instances even if they use the same scope annotation.)

```dart
import 'package:jugger/jugger.dart';

@Component()
@singleton
abstract class MyComponent {
  @subcomponentFactory
  MySubcomponent createMySubcomponent();

  @subcomponentFactory
  MySubcomponent2 createMySubcomponent2();
}

@Subcomponent()
@MyScope()
abstract class MySubcomponent {}

@Subcomponent()
@MyScope()
abstract class MySubcomponent2 {}
```

#### Subcomponent with builder

A subcomponent as a component can have a builder. It is also specified in the @Subcomponent annotation. In the method of the parent component, you need to specify it as the only parameter.

```dart
import 'package:jugger/jugger.dart';

@Component()
abstract class MyComponent {
  @subcomponentFactory
  MySubcomponent createMySubcomponent(MySubcomponentBuilder builder);
}

@Subcomponent(
  builder: MySubcomponentBuilder,
)
abstract class MySubcomponent {
  String getString();
}

@componentBuilder
abstract class MySubcomponentBuilder {
  MySubcomponentBuilder setString(String s);

  MySubcomponent build();
}
```

Create a component instance like so:

```dart
  final MyComponent myComponent = JuggerMyComponent.create();
  MySubcomponent mySubcomponent = myComponent.createMySubcomponent(
    JuggerSubcomponent$MySubcomponentBuilder().setString("Hello"),
  );
  print(mySubcomponent.getString());
```

### Scope

You can define your own scope. Their goal is to reuse instances of object instances within a single component.

```dart
@scope
class MyScope {
  const MyScope._();
}

const MyScope myScope = MyScope._();
```

### Component builder

The component may need external objects to use for the dependency graph. To do this, you need to use a `component builder`. Declare an abstract class annotated with the `@componentBuilder` annotation. It must contain a requered `build()` method with a return type of the component. For each external dependency, you need to declare a method with a builder return type and which contains a single parameter.

```dart
import 'package:example/main.jugger.dart';
import 'package:jugger/jugger.dart';

void main() {
  final MyComponent myComponent =
      JuggerMyComponentBuilder().helloString('hello').build();

  print(myComponent.getString());
}

@Component(
  builder: MyComponentBuilder,
)
abstract class MyComponent {
  String getString();
}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponentBuilder helloString(String s);

  MyComponent build();
}
```
Dependencies provided by the builder are used in the dependency graph to construct other dependencies.

```dart
...
@componentBuilder
abstract class MyComponentBuilder {
  MyComponentBuilder setDouble(double d);

  MyComponent build();
}

@module
abstract class MyModule {
  @provides
  @singleton
  static int provideInteger() => 0;

  @provides
  static String provideSting(
    int i, // used from this module
    double d, // user from component builder
  ) =>
      '$i, $d';
}
```
### Component as dependency

A component can depend on other components in order to use its returned objects as dependencies.

```dart
import 'package:example/main.jugger.dart';
import 'package:jugger/jugger.dart';

void main() {
  // creates the first component
  final FirstComponent firstComponent = JuggerFirstComponent.create();

  final SecondComponent secondComponent = JuggerSecondComponentBuilder()
      // passing an instance of the first component
      .setFirstComponent(firstComponent)
      .build();

  print(secondComponent.getString());
}

@Component(
  modules: <Type>[FirstModule],
)
@singleton
abstract class FirstComponent {
  // important! in order for the second component to use it to build objects,
  // you need to add a method that returns it.
  int getInt();
}

@module
abstract class FirstModule {
  @provides
  @singleton
  static int provideInteger() => 0;
}

@Component(
  // specify that use the first component as a dependency
  dependencies: <Type>[FirstComponent],
  modules: <Type>[SecondModule],
  builder: SecondComponentBuilder,
)
@singleton
abstract class SecondComponent {
  String getString();
}

// Component builder is required if you use the component as a dependency.
@componentBuilder
abstract class SecondComponentBuilder {
  // set the first component
  SecondComponentBuilder setFirstComponent(FirstComponent component);

  SecondComponent build();
}

@module
abstract class SecondModule {
  @provides
  @singleton
  static double provideDouble() => 0.0;

  @provides
  static String provideSting(
    int i, // used from first component
    double d, // used from this module
  ) =>
      '$i, $d';
}
```

### Module

`Module` are a simple class which contain logic for creating objects. Modules only contain methods which provide dependency. Generally, each Module includes objects which relate to some part of the application’s logic.

```dart
@module
abstract class <ModuleName> {
  ...
  provide and binds methods
  ...
}
```

`Module` must be abstract and contains only static or abstact methods.

### Included modules
Additional modules contributions of the modules in `includes`, and of their inclusions recursively, are all contributed to the object graph.
```dart
@Module(includes: <Type>[Module2, Module3])
abstract class Module1 {
...
```

### Provide method

Method annotated with the `@provides` annotation return instances of classes that which are used in the dependency graph.

```dart
@provides
static String provideSting() => 'hello';
```

A method can contain parameters that construct the object it returns. "dependencies" must also be provided in the same or another module.

```dart
@provides
static int provideInteger() => 0;

@provides
static double provideDouble() => 0.0;
  
@provides
static String provideSting(int i, double d) => '$i, $d';
```

### Bind method
A `@binds` method is the same as `@provides`, but it binds the interface to the implementation. The method must be abstract and have one parameter that implements the return type.

```dart
abstract class MyInterface { }

class MyImplementation implements MyInterface {
  @inject
  const MyImplementation();
}

@module
abstract class MyModule {
  @binds
  MyInterface bindMyClass(MyImplementation impl);
}
```

### Singleton
This annotation is used to indicate only a single instance of dependency object is created.
NOTE: this scope is applied for each module separately!

Can be applied to methods in a module and to a class constructor.

```dart
@provides
@singleton // Tell the graph that there can be only single instance.
static int provideInteger() => 0;
```

```dart
@singleton // Will be used if there is no provider for this class.
class MyClass {
  @inject
  const MyClass();
}
```

### Inject

The annotation told the jugger whether the annotated would be used when building the graph.

### Injected constructor

The annotation told the jugger whether the given class would be used when building the graph.

```dart
class MyClass {
  @inject
  const MyClass();
}
```

For such a class, you can not declare a provider method in the module, the jugger will understand this and generate it himself.

```dart 
import 'package:example/main.jugger.dart';
import 'package:jugger/jugger.dart';

void main() {
  final MyComponent firstComponent = JuggerMyComponent.create();
  print(firstComponent.getStringProvider().getString());
}

@Component(
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  StringProvider getStringProvider();
}

@module
abstract class MyModule {
  @provides
  static int provideInteger() => 0;

  @provides
  static double provideDouble() => 0.0;
}

class StringProvider {
  // inject the constructor, the jugger itself creates a provider for this class
  @inject
  // will use dependencies from the module in which it is used
  const StringProvider(this.d, this.i);

  final int i;
  final double d;

  String getString() => '$i, $d';
}
```

### Injected method

The method can also be injected. it will be called when the jugger creates an instance of the class.

```dart
import 'package:example/main.jugger.dart';
import 'package:jugger/jugger.dart';

void main() {
  final MyComponent firstComponent = JuggerMyComponent.create();
  print(firstComponent.getStringProvider().getString());
}

@Component(
  modules: <Type>[MyModule],
)
abstract class MyComponent {
  StringProvider getStringProvider();
}

@module
abstract class MyModule {
  @provides
  static int provideInteger() => 0;

  @provides
  static double provideDouble() => 0.0;
}

class StringProvider {
  @inject
  StringProvider(this.d);

  final double d;

  String? _s;

  // inject the method
  @inject
  // will use dependencies from the module in which it is used
  void init(int i) {
    _s = '$i, $d';
  }

  String getString() => _s ?? '';
}
```

### Qualifiers

@Qualifier annotation is used to distinguish between objects of the same type but with different instances.
Example of Named qulifier:
```dart
@module
abstract class AppModule {
  @provides
  @Named('dev')
  static AppConfig provideDevAppConfig() {
    return const AppConfig('https://dev.com/');
  }

  @provides
  @Named('release')
  static AppConfig provideReleaseAppConfig() {
    return const AppConfig('https://dev.com/');
  }

  @provides
  @singleton
  static AppConfig provideAppConfig(
    AppEnvironment environment,
    @Named('dev') AppConfig dev,
    @Named('release') AppConfig release,
  ) {
    switch (environment) {
      case AppEnvironment.dev:
        return dev;
      case AppEnvironment.release:
        return release;
    }
  }
}
```

You can also declare a custom qualifier:

```dart
@qualifier
class Release {
  const Release();
}

const Release release = Release();

@qualifier
class Dev {
  const Dev();
}

const Dev dev = Dev();
```

And use as:

```dart
@provides
@dev
static AppConfig provideDevAppConfig() {
  return const AppConfig('https://dev.com/');
}
```

### Disposable component
Objects whose life cycle is the same as the component can be disposed. Usually they are singleton objects. To dispose of such objects, you need to add a method to the component:

```dart
@Component()
abstract class AppComponent {
  Future<void> dispose();
}
```

The objects themselves must be a scoped(singleton):
```dart
@singleton
@disposable
class MySingleton {
  @inject
  constMySingleton();
}
```
Or in a module:
```dart
@module
abstract class AppModule {
  @provides
  @singleton
  @disposable
  static MySingleton provideMySingleton() => MySingleton();
}
```

Disposable objects must have a dispose method:
```dart
class MySingleton {
  @inject
  const MySingleton();

  void dispose() { }
  // or
  Future<void> dispose() async {}
}
```

If it is not possible to declare a dispose method, you can assign another method for disposal.

To do this, you need to specify the delegated strategy for the disposable annotation:
```dart
@provides
@singleton
@Disposable(strategy: DisposalStrategy.delegated)
static MySingleton provideMySingleton() => MySingleton();
```

And add a method to the module to dispose of the object:
```dart
@disposalHandler
static Future<void> disposeMySingleton(MySingleton mySingleton) async {
  await mySingleton.close();
}
```

The disposable object looks like this:
```dart
class MySingleton {
  @inject
  const MySingleton();

  Future<void> close() async {}
}
```
To dispose of component objects, simply call dispose. After that, the component will not be usable. The operation will be idempotent.

### Multibindings

Jugger allows you to bind several objects into a collection even when the objects are bound in different modules using multibindings. Jugger assembles the collection so that application code can inject it without depending directly on the individual bindings.

#### Set multibindings

In order to contribute one element to an injectable multibound set, add an @IntoSet annotation to your module method:

```dart
@module
abstract class Module {
  @provides
  @intoSet
  static String provideString1() => '1';

  @provides
  @intoSet
  static String provideString2() => '2';
}
```

Now the component can provide the set:

```dart
@Component(modules: <Type>[Module])
abstract class AppComponent {
  Set<String> get strings;
}
```

Or a binding in that component can depend on the set:

```dart
@provides
static int provideCount(Set<String> strings) => strings.length;
```

#### Map multibindings

Jugger lets you use multibindings to contribute entries to an injectable map as long as the map keys are known at compile time.

To contribute an entry to a multibound map, add a method to a module that returns the value and is annotated with @IntoMap and with another custom annotation that specifies the map key for that entry.

For maps with keys that are strings or boxed primitives, use one of the standard annotations:

```dart
@module
abstract class Module {
  @provides
  @intoMap
  @StringKey('b')
  static int provideInt1() => 1;

  @provides
  @intoMap
  @StringKey('a')
  static int provideInt2() => 2;
}

@Component(modules: <Type>[Module])
abstract class AppComponent {
  Map<String, int> get ints;
}
```

The following key types are supported:
- String
- int
- double
- bool
- Type
- Enum

Jugger already has several pre-built annotations:
- @StringKey
- @IntKey
- @TypeKey

But you can also create a custom annotation:

```dart
@mapKey
class MyKey {
  const MyKey(this.value);

  final double value;
}
```

### Lazy initialization

Sometimes a dependency needs to be initialized not immediately, but later. You can use Lazy for this. This is useful for not initializing dependencies if they are not going to be used. As an example, this is the choice of which dependency to use in the provider method:

```dart
@j.provides
static Repository provideRepository(
  ILazy<OfflineRepository> offline, 
  ILazy<OnlineRepository> online,
  bool isOnline,
) {
    if (isOnline) {
      return online.get();
    } else {
      return offline.get();
    }
}
```
In this example, a repository will be provided, depending on the isOnline flag, you need to use a specific repository. When used, the Lale one will only initialize the required repository.

### build.yaml

```yaml
targets:
  $default:
    builders:
      jugger_generator:
        options:
          remove_interface_prefix_from_component_name: true
          check_unused_providers: true
          generated_file_line_length: 80
```

### remove_interface_prefix_from_component_name

If your components have a prefix in the name, then when creating the jugger class, it will be removed. By default it is turned on.

```dart
  final IMyComponent myComponent = JuggerMyComponent.create();
```
instead:
```dart
  final IMyComponent myComponent = JuggerIMyComponent.create();
```

### check_unused_providers:

If there are classes in the graph that are not used, the generation will fall. By default it is turned on.

### generated_file_line_length:

The number of characters allowed in a single line of generated file. Default value is 80.

# Migration

## From 2.* to 3.*

Version 3 contains breaking changes, to upgrade to this version you need to do the following:

### Scope related changes

When using the singleton scope annotation, you also need to annotate the component with the same annotation.

```dart
import 'package:jugger/jugger.dart';

@Component(modules: <Type>[MyComponentModule])
@singleton // <----
abstract class MyComponent {
  String getString();
}

@module
abstract class MyComponentModule {
  @provides
  @singleton // <----
  static String provideString() => '';
}
```

### Component builder related changes

If the component has a builder, it must be explicitly specified in the annotation @Component.

```dart
import 'package:jugger/jugger.dart';

@Component(
  builder: MyComponentBuilder, // <----
)
abstract class MyComponent {
  String getString();
}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponentBuilder setString(String s);

  MyComponent build();
}
```

### Lazy provider related changes

The ILazy contract has changed, now you need to use **value** instead of the **get()** method.

```dart
abstract class ILazy<T> {
  T get value;
}
```

# Links

Telegram chat: https://t.me/jugger_chat
