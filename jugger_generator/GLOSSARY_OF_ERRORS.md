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

### component_builder_type_provided_multiple_times
Component builder can have only one method corresponding to single type.

`BAD:`
```dart
@componentBuilder
abstract class MyComponentBuilder {
  MyComponentBuilder setString(String s);

  MyComponentBuilder setString2(String s);

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