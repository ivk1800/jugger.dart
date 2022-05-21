import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';

import '../utils/dart_type_ext.dart';
import '../utils/utils.dart';
import 'tag.dart';
import 'visitors.dart';

/// Wrapper class for component classes that are annotated by [Component].
/// The client of this class must check that the element is definitely a
/// Component.
class Component {
  Component._({
    required this.element,
    required this.annotations,
    required this.memberInjectors,
    required this.provideMethods,
    required this.provideProperties,
    required this.modules,
    required this.dependencies,
    required this.modulesProvideMethods,
  });

  factory Component.fromElement(
    ClassElement element,
    ComponentAnnotation component,
  ) {
    final List<ModuleAnnotation> modules = component.modules;
    return Component._(
      element: element,
      annotations: <Annotation>[component],
      memberInjectors: element.getMemberInjectors(),
      provideMethods: element.getComponentProvideMethods()
        ..sort((MethodElement a, MethodElement b) => a.name.compareTo(b.name)),
      provideProperties: element.getProvideProperties()
        ..sort((PropertyAccessorElement a, PropertyAccessorElement b) =>
            a.name.compareTo(b.name)),
      modules: modules,
      dependencies: component.dependencies,
      modulesProvideMethods: modules
          .map((ModuleAnnotation module) => module.moduleElement.getProvides())
          .expand((List<Method> methods) => methods)
          // if module is used several times, just make unique methods
          .toSet()
          .toList(),
    );
  }

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

  /// Returns the modules that are included to the component.
  final List<ModuleAnnotation> modules;

  /// Returns the another components that are included to the component as
  /// dependencies.
  final List<DependencyAnnotation> dependencies;

  /// Returns all methods of modules that are included to the component.
  /// Methods are not repeated if one module is used several times.
  final List<Method> modulesProvideMethods;

  /// Returns methods of the component that return some type, do not include
  /// methods with the void type.
  ///
  /// Example of method:
  /// ```dart
  /// @Component(modules: <Type>[AppModule])
  /// abstract class AppComponent {
  ///   String getName(); // <---
  /// }
  /// ```
  final List<MethodElement> provideMethods;

  /// Returns properties of the component that return some type.
  ///
  /// Example of method:
  /// ```dart
  /// @Component(modules: <Type>[AppModule])
  /// abstract class AppComponent {
  ///   String get name; // <---
  /// }
  /// ```
  final List<PropertyAccessorElement> provideProperties;
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
///     String s, // <---
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

  /// Element associated with this dependency.
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

  /// All annotations of the current method.
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
