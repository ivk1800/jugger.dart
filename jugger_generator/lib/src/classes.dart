import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';

import 'tag.dart';
import 'utils.dart';
import 'visitors.dart';

/// Wrapper class for component classes that are annotated by [inject].
/// The client of this class must check that the element is definitely a
/// Component.
class Component {
  Component({
    required this.element,
    required this.annotations,
    required this.memberInjectors,
  });

  /// Element associated with this component.
  final ClassElement element;

  /// All annotation of the component.
  final List<Annotation> annotations;

  /// All methods that use for injection of classes.
  /// Example:
  /// ```dart
  /// @Component(modules: <Type>[AppModule])
  /// abstract class AppComponent {
  ///   void inject(MyClass myClass); // there her is
  /// }
  /// ```
  final List<MemberInjectorMethod> memberInjectors;

  // region private

  late final ComponentAnnotation? _componentAnnotation = () {
    final Annotation? annotation = annotations
        .firstWhereOrNull((Annotation a) => a is ComponentAnnotation);
    return annotation is ComponentAnnotation ? annotation : null;
  }();

  late final List<ModuleAnnotation> _modules =
      _componentAnnotation?.modules ?? List<ModuleAnnotation>.empty();

  late final List<DependencyAnnotation> _dependencies =
      _componentAnnotation?.dependencies ?? List<DependencyAnnotation>.empty();

  late final List<Method> _modulesProvideMethods = modules
      .map((ModuleAnnotation module) => module.moduleElement.getProvides())
      .expand((List<Method> methods) => methods)
      // if module is used several times, just make unique methods
      .toSet()
      .toList();

  late final List<MethodElement> _provideMethods = () {
    final List<MethodElement> methods = element.getComponentProvideMethods();
    return methods
      ..sort((MethodElement a, MethodElement b) => a.name.compareTo(b.name));
  }();

  late final List<PropertyAccessorElement> _provideProperties = () {
    final List<PropertyAccessorElement> properties =
        element.getProvideProperties();
    return properties
      ..sort((PropertyAccessorElement a, PropertyAccessorElement b) =>
          a.name.compareTo(b.name));
  }();

  // endregion private

  /// Returns the modules that are included to the component.
  List<ModuleAnnotation> get modules => _modules;

  /// Returns the another components that are included to the component as
  /// dependencies.
  List<DependencyAnnotation> get dependencies => _dependencies;

  /// Returns all methods of modules that are included to the component.
  /// Methods are not repeated if one module is used several times.
  List<Method> get modulesProvideMethods => _modulesProvideMethods;

  /// Returns methods of the component that return some type, do not include
  /// methods with the void type.
  ///
  /// Example of method:
  /// ```dart
  /// @Component(modules: <Type>[AppModule])
  /// abstract class AppComponent {
  ///   String getName(); // there he is
  /// }
  /// ```
  List<MethodElement> get provideMethods => _provideMethods;

  /// Returns properties of the component that return some type.
  ///
  /// Example of method:
  /// ```dart
  /// @Component(modules: <Type>[AppModule])
  /// abstract class AppComponent {
  ///   String get name; // there he is
  /// }
  /// ```
  List<PropertyAccessorElement> get provideProperties => _provideProperties;
}

/// Wrapper class for component builder classes that are annotated by
/// [componentBuilder].
/// The client of this class must check that the element is definitely a
/// ComponentBuilder.
class ComponentBuilder {
  ComponentBuilder({
    required this.element,
    required this.componentClass,
    required this.methods,
  });

  /// Element associated with this component builder.
  final ClassElement element;

  /// The class of the component that this builder constructs.
  final ClassElement componentClass;

  /// All method of this component builder. Each method must contain only one
  /// parameter.
  final List<MethodElement> methods;

  late final List<ComponentBuilderParameter> _parameters = methods
      .expand<ParameterElement>((MethodElement methodElement) {
        return methodElement.parameters;
      })
      .map((ParameterElement p) => ComponentBuilderParameter(parameter: p))
      .toList();

  /// Returns all parameters of this component builder, these parameters are
  /// taken from the methods.
  List<ComponentBuilderParameter> get parameters => _parameters;
}

/// Wrapper class for argument of component builder. This is a argument of
/// method of component builder.
///
/// ```dart
/// @componentBuilder
/// abstract class MyComponentBuilder {
///   MyComponentBuilder appComponent(
///     String s, // there he is
///   );
///
///   AppComponent build();
/// } ```
class ComponentBuilderParameter {
  const ComponentBuilderParameter({
    required this.parameter,
  });

  /// Element associated with this parameter.
  final ParameterElement parameter;

  @override
  String toString() => parameter.type.getName();
}

abstract class Annotation {}

/// Wrapper class for component annotation.
class ComponentAnnotation implements Annotation {
  const ComponentAnnotation({
    required this.modules,
    required this.dependencies,
  });

  /// Returns the modules that are included to the component.
  final List<ModuleAnnotation> modules;

  /// Returns the another components that are included to the component as
  /// dependencies.
  final List<DependencyAnnotation> dependencies;
}

/// Wrapper class for provide annotation.
class ProvideAnnotation implements Annotation {}

/// Wrapper class for inject annotation.
class InjectAnnotation implements Annotation {}

/// Wrapper class for singleton annotation.
class SingletonAnnotation implements Annotation {}

/// Wrapper class for bind annotation.
class BindAnnotation implements Annotation {}

/// Wrapper class for nonLazy annotation.
class NonLazyAnnotation implements Annotation {}

/// Wrapper class for componentBuilder annotation.
class ComponentBuilderAnnotation implements Annotation {
  const ComponentBuilderAnnotation(this.element);

  final ClassElement element;
}

/// Wrapper class for module annotation.
class ModuleAnnotation implements Annotation {
  const ModuleAnnotation({
    required this.moduleElement,
    required this.includes,
  });

  /// Element associated with this module.
  final ClassElement moduleElement;

  /// Returns the modules that are included to the module.
  final List<ModuleAnnotation> includes;
}

/// Wrapper class for component annotation that uses as 'dependency' of
/// component.
class DependencyAnnotation implements Annotation {
  const DependencyAnnotation({required this.element});

  /// Element associated with this depencendy.
  final ClassElement element;
}

/// Wrapper class for qualifier annotation.
class QualifierAnnotation implements Annotation {
  const QualifierAnnotation({
    required this.tag,
  });

  final Tag tag;

  @override
  int get hashCode => tag.hashCode;

  @override
  bool operator ==(Object other) =>
      other is QualifierAnnotation && other.tag == tag;
}

/// Wrapper class for provide method of module.
class Method {
  Method(this.element);

  final MethodElement element;

  /// All methods of the current method.
  late final List<Annotation> annotations = getAnnotations(element);

  late final QualifierAnnotation? _qualifierAnnotation = () {
    final Annotation? annotation = annotations
        .firstWhereOrNull((Annotation a) => a is QualifierAnnotation);
    return annotation is QualifierAnnotation ? annotation : null;
  }();

  late final Tag? _tag = _qualifierAnnotation?.tag;

  /// Tag associated with the current method.
  Tag? get tag => _tag;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other.runtimeType == runtimeType &&
          other is Method &&
          other.element == element);

  @override
  int get hashCode => element.hashCode;
}

class MemberInjectorMethod {
  const MemberInjectorMethod(this.element);

  final MethodElement element;
}

class InjectedMember {
  const InjectedMember(this.element);

  final FieldElement element;

  @override
  int get hashCode => element.name.hashCode;

  @override
  bool operator ==(Object other) =>
      other is InjectedMember && other.element.name == element.name;
}
