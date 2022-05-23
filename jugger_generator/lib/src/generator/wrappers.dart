import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:jugger/jugger.dart' as j;

import '../errors_glossary.dart';
import '../utils/dart_type_ext.dart';
import '../utils/element_ext.dart';
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
    required this.methodsAccessors,
    required this.propertiesAccessors,
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
      memberInjectors: element.getComponentMemberInjectorMethods(),
      methodsAccessors: element
          .getComponentMethodsAccessors()
          // Sort so that the sequence is preserved with each code generation (for
          // test stability)
          .sortedByCompare<String>(
            (MethodObjectAccessor element) => element.method.name,
            (String a, String b) => a.compareTo(b),
          ),
      propertiesAccessors: element
          .getComponentPropertiesAccessors()
          // Sort so that the sequence is preserved with each code generation (for
          // test stability)
          .sortedByCompare<String>(
            (PropertyObjectAccessor element) => element.property.name,
            (String a, String b) => a.compareTo(b),
          ),
      modules: modules,
      dependencies: component.dependencies,
      modulesProvideMethods: modules
          .map((ModuleAnnotation module) => module.moduleElement.getProvides())
          .expand((List<ProvideMethod> methods) => methods)
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
  final List<ProvideMethod> modulesProvideMethods;

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
  final List<MethodObjectAccessor> methodsAccessors;

  /// Returns properties of the component that return some type.
  ///
  /// Example of method:
  /// ```dart
  /// @Component(modules: <Type>[AppModule])
  /// abstract class AppComponent {
  ///   String get name; // <---
  /// }
  /// ```
  final List<PropertyObjectAccessor> propertiesAccessors;
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

/// Base class of method of Module.
abstract class ModuleMethod {
  ModuleMethod({
    required this.element,
    required this.annotations,
  });

  final MethodElement element;
  final List<Annotation> annotations;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other.runtimeType == runtimeType &&
          other is ModuleMethod &&
          other.element == element);

  @override
  int get hashCode => element.hashCode;
}

/// Wrapper class for provide method of module.
abstract class ProvideMethod extends ModuleMethod {
  ProvideMethod({
    required MethodElement element,
    required List<Annotation> annotations,
    required this.tag,
  }) : super(element: element, annotations: annotations);

  final Tag? tag;
}

/// Static provide method.
class StaticProvideMethod extends ProvideMethod {
  StaticProvideMethod._({
    required MethodElement element,
    required List<Annotation> annotations,
    required Tag? tag,
  }) : super(element: element, annotations: annotations, tag: tag);

  /// Create method from element and validate.
  factory StaticProvideMethod.fromMethodElement(MethodElement methodElement) {
    check(
      methodElement.returnType.element is ClassElement,
      () => buildUnexpectedErrorMessage(
        message: '${methodElement.returnType.element} not supported.',
      ),
    );
    return StaticProvideMethod._(
      element: methodElement,
      annotations: getAnnotations(methodElement),
      tag: getQualifierAnnotation(methodElement)?.tag,
    );
  }
}

/// Bind provide method.
class AbstractProvideMethod extends ProvideMethod {
  AbstractProvideMethod._({
    required MethodElement element,
    required List<Annotation> annotations,
    required Tag? tag,
    required this.assignableType,
    required this.type,
  }) : super(element: element, annotations: annotations, tag: tag);

  /// Create method from element and validate.
  factory AbstractProvideMethod.fromMethodElement(MethodElement element) {
    final Element moduleElement = element.enclosingElement;
    check(
      element.parameters.length == 1,
      () => buildErrorMessage(
        error: JuggerErrorId.invalid_bind_method,
        message:
            'Method ${moduleElement.name}.${element.name} annotated with ${j.binds.runtimeType} must have one parameter.',
      ),
    );

    final DartType parameterType = element.parameters.first.type;
    parameterType.checkUnsupportedType();
    final ClassElement? typeElement =
        parameterType.element?.castToOrThrow<ClassElement>();

    final bool isSupertype = typeElement!.allSupertypes.any(
        (InterfaceType interfaceType) => interfaceType == element.returnType);

    check(
      isSupertype,
      () => buildErrorMessage(
        error: JuggerErrorId.bind_wrong_type,
        message:
            'Method ${moduleElement.name}.${element.name} parameter type must be assignable to the return type.',
      ),
    );

    final Element rawParameter = element.parameters[0].type.element!;
    check(
      element.returnType.element is ClassElement,
      () => buildUnexpectedErrorMessage(
        message: '${element.returnType.element} not supported.',
      ),
    );
    return AbstractProvideMethod._(
      assignableType: rawParameter.castToOrThrow<ClassElement>().thisType,
      element: element,
      annotations: getAnnotations(element),
      tag: getQualifierAnnotation(element)?.tag,
      type: element.returnType,
    );
  }

  final DartType type;
  final DartType assignableType;
}

// region component

/// Base wrapper for member of component.
abstract class ComponentMethod {
  const ComponentMethod();
}

/// Wrapper for method member.
/// ```dart
/// @Component()
/// abstract class AppComponent {
///  String getString(); <---
/// }
/// ```
class MethodObjectAccessor extends ComponentMethod {
  MethodObjectAccessor(this.method);

  final MethodElement method;
}

/// Wrapper for property member.
/// ```dart
/// @Component()
/// abstract class AppComponent {
///  String get string; <---
/// }
/// ```
class PropertyObjectAccessor extends ComponentMethod {
  PropertyObjectAccessor(this.property);

  final PropertyAccessorElement property;
}

/// Wrapper for method for inject object.
/// ```dart
/// @Component()
/// abstract class AppComponent {
///   void inject(InjectedClass c); <---
/// }
/// ```
class MemberInjectorMethod extends ComponentMethod {
  const MemberInjectorMethod(this.element);

  final MethodElement element;
}

// endregion component

class InjectedMember {
  const InjectedMember(this.element);

  final FieldElement element;

  @override
  int get hashCode => element.name.hashCode;

  @override
  bool operator ==(Object other) =>
      other is InjectedMember && other.element.name == element.name;
}
