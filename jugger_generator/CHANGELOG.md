## 3.1.1

* Upgrade analyzer.

## 3.1.0

* Restrict analyzer version to >=4.7.0 <6.0.0.
* Dart 2.15: ignore all lint rules for file.
* Improving the error when no provider is found for an abstract class.
* Ignoring injected constructors in an abstract class instead of generating code with a syntax error.
* Support factory and named constructors for inject.
* Support positioned and named arguments together in injected constructor.

## 3.0.0

* **Breaking**: Check [migration guide](https://github.com/ivk1800/jugger.dart#from-2-to-3) from version 2 to 3.
* Feature: subcomponents.
* Feature: custom scopes.

## 2.5.1

* Add check: The component does not contain disposable objects, but the dispose method is declared.
* Do not allow non-scoped objects to be initialized as non lazy;
* Allow declare component builder in separated file;
* Fix disposable manager generation error if multiple components declared in single file;
* Fix multibindings generation error if multiple components declared in single file;

## 2.5.0

* Feature: multibindings.
* Feature: lazy provider.

## 2.4.0

* Feature: disposable component. 
* Support analyzer 4.0.0.
* Added entry points into error report.

## 2.3.0

* Internal refactoring.
* Add docs.
* Add glossary of errors with a description.
* Fix detecting multiple providers for same type.
* Skip generation if there is nothing to generate.
* Fix ignored the methods of the ancestors of the component.
* Fix generation if different types have same name.
* Fix ignored qualifier from component argument.
* Check unsupported type in generic.
* Check invalid members in component, component builder and module.
* Custom line-length for generated file. `generated_file_line_length`

## 2.2.1

* Fix generation if component not used modules, and all classes have injected constructor.
* Fix generation of objects with qualifier of the same type but with different instances.
* Fix inject method of class, if its class is not used in the component.
* Improve generation of qualifiers.
* Internal code improves.
* Add docs about qualifiers.

## 2.2.0

* Add includes for module
```dart
@Module(includes: <Type>[Module2, Module3])
abstract class Module1 {
...
```
* Fix generation of class with injected constructor

## 2.1.0

Fix generation issues.
Check unsupported types and fails build.
Feature: Injected Method.
Added more tests.
Update documentation.
check_unused_providers true by default.

## 2.0.0

jugger_generator is now stable

## 1.1.0+4-alpha

* support nullsafety

## 1.1.0+2-alpha

* fix generation bug with @Named annotation

## 1.1.0+1-alpha

* Ignore files of tests

## 1.1.0-alpha

* Add annotations: ComponentBuilder, Named. Improve generation

## 1.0.0-alpha

* First release
