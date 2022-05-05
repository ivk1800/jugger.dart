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