### missing_build_method
The component builder must have a required `build` method that returns an instance of the compoennt that constructs.

`BAD:`
```dart
@componentBuilder
abstract class AppComponentBuilder {
  AppComponentBuilder setString(String s);
}
```

`GOOD:`
```dart
@componentBuilder
abstract class AppComponentBuilder {
  AppComponentBuilder setString(String s);

  AppComponent build();
}
```

### wrong_type_of_build_method
Required `build` method of component builder must return type of the component that constructs.

`BAD:`
```dart
@componentBuilder
abstract class AppComponentBuilder {
  AppComponentBuilder setString(String s);

  String build();
}
```

`GOOD:`
```dart
@componentBuilder
abstract class AppComponentBuilder {
  AppComponentBuilder setString(String s);

  AppComponent build();
}
```

### missing_component_dependency
If a component uses another component as a dependency, it must be passed in the component's builder arguments.

`BAD:`
```dart
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {}

@Component(dependencies: <Type>[AppComponent])
abstract class MyComponent {}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponent build();
}
```

`GOOD:`
```dart
@Component()
abstract class AppComponent {}

@Component(dependencies: <Type>[AppComponent])
abstract class MyComponent {}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponentBuilder setAppComponent(AppComponent appComponent);
  MyComponent build();
}
```

### invalid_component
Component should only have abstract classes as ancestor.

`BAD:`
```dart
class Ancestor1 {}

@Component(modules: <Type>[Module1])
abstract class AppComponent extends Ancestor1 {
  String getString1();
}
```

`GOOD:`
```dart
abstract class Ancestor1 {}

@Component(modules: <Type>[Module1])
abstract class AppComponent extends Ancestor1 {
  String getString1();
}
```

### unscoped_non_lazy
It makes no sense to initialize a non-scoped object.

`BAD:`
```dart
@provides
@nonLazy
static NonLazyRepository provideNonLazyRepository() => NonLazyRepository();
```

`GOOD:`
```dart
@singleton
@provides
@nonLazy
static NonLazyRepository provideNonLazyRepository() => NonLazyRepository();
```


### public_component_builder
Component builder must be public because it is an interface and it is implemented in another file.

`BAD:`
```dart
@componentBuilder
abstract class _AppComponentBuilder {
  AppComponent build();
}
```

`GOOD:`
```dart
@componentBuilder
abstract class AppComponentBuilder {
  AppComponent build();
}
```

### component_builder_invalid_method_parameters
A component builder method should have only one parameter. If you need to pass multiple arguments, you need to pass them in separate methods.

`BAD:`
```dart
@componentBuilder
abstract class ComponentBuilder {
  ComponentBuilder setInt();
  ComponentBuilder setArgs(String s, int i);

  AppComponent build();
}
```

`GOOD:`
```dart
@componentBuilder
abstract class ComponentBuilder {
  ComponentBuilder setInt(int i);
  ComponentBuilder setString(String s);

  AppComponent build();
}
```

### component_builder_invalid_method_type
All methods that set an argument must have a builder type.

`BAD:`
```dart
@componentBuilder
abstract class ComponentBuilder {
  AppComponent setInt(int i);

  AppComponent build();
}
```

`GOOD:`
```dart
@componentBuilder
abstract class ComponentBuilder {
  ComponentBuilder setInt(int i);

  AppComponent build();
}
```

### wrong_arguments_of_build_method
Build method should not contain arguments.

`BAD:`
```dart
@componentBuilder
abstract class ComponentBuilder {
  AppComponent build(int i);
}
```

`GOOD:`
```dart
@componentBuilder
abstract class ComponentBuilder {
  AppComponent build();
}
```

### component_builder_private_method
All methods of the component builder must be public.

`BAD:`
```dart
@componentBuilder
abstract class MyComponentBuilder {
  MyComponentBuilder _setString(String s);

  AppComponent build();
}
```

`GOOD:`
```dart
@componentBuilder
abstract class MyComponentBuilder {
  MyComponentBuilder setString(String s);

  AppComponent build();
}
```

### public_component
Component must be public.

`BAD:`
```dart
@Component()
abstract class _Component {}
```

`GOOD:`
```dart
@Component()
abstract class Component {}
```

### abstract_component
Component must be abstract.

`BAD:`
```dart
@Component()
class AppComponent {}
```

`GOOD:`
```dart
@Component()
abstract class AppComponent {}
```

### invalid_component_dependency
A component can only depend on another component.

`BAD:`
```dart
@Component(dependencies: <Type>[int])
abstract class FirstComponent {}
```

`GOOD:`
```dart
@Component(dependencies: <Type>[SecondComponent])
abstract class FirstComponent {}

@Component()
abstract class SecondComponent {}
```

### component_depend_himself
A component cannot depend on himself.

`BAD:`
```dart
@Component(dependencies: <Type>[AppComponent])
abstract class AppComponent {}
```

`GOOD:`
```dart
@Component(dependencies: <Type>[])
abstract class AppComponent {}
```

### public_module
Module must be public.

`BAD:`
```dart
@module
abstract class _Module {}
```

`GOOD:`
```dart
@module
abstract class Module {}
```

### abstract_module
Module must be abstract.

`BAD:`
```dart
@module
class Module {}
```

`GOOD:`
```dart
@module
abstract class Module {}
```

### module_annotation_required
Module class must be annotated with @module.

`BAD:`
```dart
abstract class Module {}
```

`GOOD:`
```dart
@module
abstract class Module {}
```

### repeated_modules
Not allowed to have multiple modules of the same type. 
Does not apply if the same module is used in different modules as includes.

`BAD:`
```dart
@Component(modules: <Type>[AppModule, AppModule])
abstract class AppComponent { }
```

`GOOD:`
```dart
@Component(modules: <Type>[AppModule])
abstract class AppComponent { }
```

### missing_provides_annotation
Static methods in modules must be annotated with @Provides.

`BAD:`
```dart
@Module()
abstract class Module1 {
  static String provideString() => '';
}
```

`GOOD:`
```dart
@Module()
abstract class Module1 {
  @provides
  static String provideString() => '';
}
```

### missing_bind_annotation
Abstract methods in modules must be annotated with @binds.

`BAD:`
```dart
@Module()
abstract class Module1 {
  Pattern bindPattern(String impl);
}
```

`GOOD:`
```dart
@Module()
abstract class Module1 {
  @binds
  Pattern bindPattern(String impl);
}
```

### unsupported_method_type
Methods of the module must be abstract or static.

`BAD:`
```dart
@Module()
abstract class Module1 {
  @provides
  String providerString() => '';
}
```

`GOOD:`
```dart
@Module()
abstract class Module1 {
  @provides
  static String providerString() => '';
}
```

### private_method_of_module
Methods of the module can not be private.

`BAD:`
```dart
@Module()
abstract class Module1 {
  @provides
  static String _providerString() => '';
}
```

`GOOD:`
```dart
@Module()
abstract class Module1 {
  @provides
  static String providerString() => '';
}
```

### bind_wrong_type
Parameter type of method must be assignable to the return type.

`BAD:`
```dart
@Module()
abstract class Module1 {
  @binds
  Pattern bindPattern(int impl);
}
```

`GOOD:`
```dart
@Module()
abstract class Module1 {
  @binds
  Pattern bindPattern(String impl);
}
```

### ambiguity_of_provide_method
Method of module can not be annotated together with @Provides and @Binds.

`BAD:`
```dart
@Module()
abstract class Module1 {
  @binds
  @provides
  Pattern bindPattern(String impl);
}
```

`GOOD:`
```dart
@Module()
abstract class Module1 {
  @binds
  Pattern bindPattern(String impl);
}
```

### type_not_supported
Jugger does not support some types, they should not be used. 
Such types include nullable.

`BAD:`
```dart
@module
abstract class AppModule {
  @provides
  static String? providesString() => '';
}
```

`GOOD:`
```dart
@module
abstract class AppModule {
  @provides
  static String providesString() => '';
}
```

### missing_injected_constructor
For a class to be used in an object graph, it must have only one constructor injected.
If there is no injected constructor, the jugger will not understand what to do.

`BAD:`
```dart
class MyClass {
  MyClass();
}
```

`GOOD:`
```dart
class MyClass {
  @inject
  MyClass();
}
```

### multiple_injected_constructors

`BAD:`
```dart
class Foo {
  @inject
  Foo(this.i);

  @inject
  Foo.custom() : this.i = 0;

  final int i;
}
```

`GOOD:`
```dart
class Foo {
  @inject
  Foo(this.i);

  Foo.custom() : this.i = 0;

  final int i;
}
```

### ambiguity_of_injected_constructor
For a class to be used in an object graph, it must have only one constructor injected. 
If there is no injected constructor, the jugger will not understand what to do.

`BAD:`
```dart
class MyClass {
  MyClass();
}
```

`GOOD:`
```dart
class MyClass {
  @inject
  MyClass();
}
```

### invalid_parameters_types
Constructor or method can have only positional parameters or only named parameters.

`BAD:`
```dart
@provides
static String provideString(int numberInt, {
required int numberDouble,
}) => '';
```

`GOOD:`
```dart
static String provideString(
    int numberInt, 
    int numberDouble,
) => '';
```

### multiple_providers_for_type
Type can only have one provider.

`BAD:`
```dart
@module
abstract class MyModule {
  @provides
  static String provideSting() => '';

  @provides
  static String provideSting2() => '';
}
```

`GOOD:`
```dart
@module
abstract class MyModule {
  @provides
  static String provideSting() => '';
}
```

### invalid_injected_constructor
An injected constructor cannot be:
* private;
* named;
* factory;

`BAD:`
```dart
class MyClass {
  @inject
  MyClass._();
}

@inject
factory MyClass.create() {
  return MyClass._();
}

class MyClass {
  @inject
  MyClass.create();
}
```

`GOOD:`
```dart
class MyClass {
  @inject
  MyClass();
}
```

### invalid_method_of_component
Method of component must be public, abstract and without parameters.

`BAD:`
```dart
@Component()
abstract class AppComponent {
  String _getString(String s) => s;
}
```

`GOOD:`
```dart
@Component()
abstract class AppComponent {
  String getString();
}
```

### missing_component_builder
If a component depends on another component, it must be passed to the component builder.

`BAD:`
```dart
@Component(
  dependencies: <Type>[AppComponent],
)
abstract class MyComponent { }
```

`GOOD:`
```dart
@Component(
  dependencies: <Type>[AppComponent],
)
abstract class MyComponent { }

@componentBuilder
abstract class MyComponentBuilder {
  MyComponentBuilder setAppComponent(AppComponent appComponent);
  MyComponent build();
}
```

### wrongComponentBuilder
The specified builder is not annotated with @componentBuilder.
The specified builder is not suitable for the component it is bound to.

`BAD:`
```dart
import 'package:jugger/jugger.dart';

@Component(builder: MyComponentBuilder)
abstract class AppComponent {}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponent build();
}

@Component(builder: MyComponentBuilder)
abstract class MyComponent {}
```

`GOOD:`
```dart
import 'package:jugger/jugger.dart';

@Component(builder: AppComponentBuilder)
abstract class AppComponent {}

@componentBuilder
abstract class AppComponentBuilder {
  AppComponent build();
}

@Component(builder: MyComponentBuilder)
abstract class MyComponent {}

@componentBuilder
abstract class MyComponentBuilder {
  MyComponent build();
}
```

### circular_dependency
Jugger detect circular dependencies. Common error if two classes depend on each other.

`BAD:`
```dart
class Class1 {
  @inject
  Class1(this.class2);
  
  final Class2 class2;
}
class Class2 {
  @inject
  Class2(this.class1);

  final Class1 class1;
}
```

### provider_not_found
The jugger doesn't understand you because it can't determine the provider for the type. 
Providers can be:
1) Method of module; 
2) Component arguments;
3) Other component;
4) If none of the above providers was found, the jugger looks at the injected constructor;

### unused_generated_providers
If there is a registered object in the graph, but it is not used in the construction of objects, jugger will throw an 
error. This is the default behavior if you want to disable:

build.yaml

```yaml
targets:
  $default:
    builders:
      jugger_generator:
        options:
          check_unused_providers: false
```

### multiple_qualifiers
Multiple qualifiers not allowed.

`BAD:`
```dart
@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  @Named('name')
  @Named('name1')
  AppConfig get appConfig;
}
```

`GOOD:`
```dart
@Component(modules: <Type>[AppModule])
abstract class AppComponent {
  @Named('name')
  AppConfig get appConfig;
  
  @Named('name1')
  AppConfig get appConfig1;
}
```

### invalid_injectable_method
Injectable method must have one parameter.

`BAD:`
```dart
@Component()
abstract class AppComponent {
  void inject(int i, String s);
}
```

`GOOD:`
```dart
@Component()
abstract class AppComponent {
  void inject(int i);
}
```

### invalid_injected_method
Injected method must be public and instance method.

`BAD:`
```dart
@inject
static void init(int i) {}
```

`GOOD:`
```dart
@inject
void init(int i) {}
```

### invalid_bind_method
Bind method must have one parameter.

`BAD:`
```dart
 @binds
  String bindString(String s, int i);
```

`GOOD:`
```dart
 @binds
  String bindString(String s);
```

### modules_circular_dependency
Two modules cannot include each other.

`BAD:`
```dart
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
```

`GOOD:`
```dart
@Module()
abstract class Module1 {
  @provides
  static String providerString(int i) => '';
}

@Module()
abstract class Module2 {
  @provides
  static int providerInt() => 0;
}
```

### multiple_module_annotations

`BAD:`
```dart
@module
@module
abstract class AppModule { }
```

`GOOD:`
```dart
@module
abstract class AppModule { }
```

### invalid_member
...

### missing_dispose_method

`BAD:`
```dart
@Component()
abstract class AppComponent { }
```

`GOOD:`
```dart
@Component()
abstract class AppComponent {
  Future<void> dispose();
}
```

### missing_disposables

The component does not contain disposable objects, but the dispose method is declared.

`BAD:`
```dart
@Component()
abstract class AppComponent {
  Future<void> dispose();
}
```

`GOOD:`
```dart
@Component()
abstract class AppComponent { }
```

### invalid_handler_method
Disposal handler contract not respected, check error message for more information.

### unused_disposal_handler
A dispose handler has been declared, but it will not be used by the component.

### redundant_disposal_handler
Declared a disposal handler for an object that will be disposed of automatically, no additional handler needed.

### multiple_disposal_handlers_for_type
Multiple disposal handlers for the same type are not allowed.

### disposable_not_scoped
Disposable objects must be in a single instance within one component.

`BAD:`
```dart
class MyClass {
  @inject
  MyClass();

  void dispose() {}
}
```

`GOOD:`
```dart
@disposable
class MyClass {
  @inject
  MyClass();

  void dispose() {}
}
```

### disposable_not_supported
Disposable type not supported with binds. You need to dispose of the implementation, not the interface.

### multiple_multibinding_annotation

`BAD:`
```dart
@provides
@intoSet
@intoMap
static String provideString1() => '1';
```

`GOOD:`
```dart
@disposable
@provides
@intoSet
static String provideString1() => '1';
```

### unused_multibinding

`BAD:`
```dart
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
```

`GOOD:`
```dart
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
  static String provideString1() => '1';
}
```

### multibindings_duplicates_keys

`BAD:`
```dart
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
```

`GOOD:`
```dart
@module
abstract class Module1 {
  @provides
  @intoMap
  @IntKey(1)
  static String provideString1() => '1';

  @provides
  @intoMap
  @IntKey(2)
  static String provideString2() => '2';
}
```

### multibindings_missing_key

`BAD:`
```dart
@module
abstract class Module1 {
  @provides
  @intoMap
  static String provideString2() => '2';
}
```

`GOOD:`
```dart
@module
abstract class Module1 {
  @provides
  @intoMap
  @IntKey(1)
  static String provideString2() => '2';
}
```

### multibindings_multiple_keys

`BAD:`
```dart
@module
abstract class Module1 {
  @provides
  @IntKey(1)
  @IntKey(2)
  static String provideString2() => '2';
}
```

`GOOD:`
```dart
@module
abstract class Module1 {
  @provides
  @intoMap
  @IntKey(1)
  static String provideString2() => '2';
}
```

### multibindings_invalid_key

`BAD:`
```dart
@mapKey
class MyKey {
  const MyKey(this.value2);

  final bool key;
}
```

`GOOD:`
```dart
@mapKey
class MyKey {
  const MyKey(this.value2);

  final bool value;
}
```

### multibindings_unsupported_key_type

Supported types:
- String
- int
- double
- bool
- Type
- Enum

