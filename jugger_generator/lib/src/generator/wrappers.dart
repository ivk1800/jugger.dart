import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:jugger/jugger.dart' as j;
import 'package:jugger/jugger.dart';

import '../errors_glossary.dart';
import '../utils/annotation_ext.dart';
import '../utils/component_methods_ext.dart';
import '../utils/dart_type_ext.dart';
import '../utils/element_annotation_ext.dart';
import '../utils/element_ext.dart';
import '../utils/list_ext.dart';
import '../utils/object_ext.dart';
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
    required this.modules,
    required this.dependencies,
    required this.modulesProvideMethods,
    required this.disposalHandlerMethods,
    required this.componentMembers,
    required this.componentBuilderType,
  });

  factory Component.fromElement(
    ClassElement element,
    BaseComponentAnnotation component,
  ) {
    final List<ModuleAnnotation> modules = component.modules;
    return Component._(
      componentBuilderType: component.builder,
      element: element,
      annotations: getAnnotations(element),
      modules: modules,
      dependencies: component.dependencies,
      modulesProvideMethods: modules
          .map((ModuleAnnotation module) => module.moduleElement.getProvides())
          .expand((List<ProvideMethod> methods) => methods)
          // if module is used several times, just make unique methods
          .toSet()
          .toList(),
      disposalHandlerMethods: _getDisposalHandlerMethodsFromModules(modules),
      componentMembers: element.getComponentMembers(),
    );
  }

  final List<ComponentMethod> componentMembers;

  final DartType? componentBuilderType;

  late final ScopeAnnotation? scope = annotations.getAnnotationOrNull();

  late final ComponentBuilder? _componentBuilder = () {
    return componentBuilderType?.resolveComponentBuilder(element.thisType);
  }();

  ComponentBuilder? resolveComponentBuilder() => _componentBuilder;

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
  late final List<MemberInjectorMethod> memberInjectors =
      componentMembers.getComponentMemberInjectorMethods();

  /// If not null, the component has such a method.
  late final DisposeMethod? disposeMethod = componentMembers.getDisposeMethod();

  /// Returns the modules that are included to the component.
  final List<ModuleAnnotation> modules;

  /// Returns the another components that are included to the component as
  /// dependencies.
  final List<DependencyAnnotation> dependencies;

  /// Returns all methods of modules that are included to the component.
  /// Methods are not repeated if one module is used several times.
  final List<ProvideMethod> modulesProvideMethods;

  final List<DisposalHandlerMethod> disposalHandlerMethods;

  late final List<SubcomponentFactoryMethod> subcomponentFactoryMethods =
      componentMembers.getSubcomponentFactoryMethods();

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
  late final List<MethodObjectAccessor> methodsAccessors = componentMembers
      .getComponentMethodsAccessors()
      // Sort so that the sequence is preserved with each code generation (for
      // test stability)
      .sortedByCompare<String>(
        (MethodObjectAccessor element) => element.method.name,
        (String a, String b) => a.compareTo(b),
      );

  /// Returns properties of the component that return some type.
  ///
  /// Example of method:
  /// ```dart
  /// @Component(modules: <Type>[AppModule])
  /// abstract class AppComponent {
  ///   String get name; // <---
  /// }
  /// ```
  late final List<PropertyObjectAccessor> propertiesAccessors = componentMembers
      .getComponentPropertiesAccessors()
      // Sort so that the sequence is preserved with each code generation (for
      // test stability)
      .sortedByCompare<String>(
        (PropertyObjectAccessor element) => element.property.name,
        (String a, String b) => a.compareTo(b),
      );
}

List<DisposalHandlerMethod> _getDisposalHandlerMethodsFromModules(
  List<ModuleAnnotation> modules,
) {
  bool equalsHelper(DisposalHandlerMethod h1, DisposalHandlerMethod h2) {
    return h1.disposableType == h2.disposableType && h1.tag == h2.tag;
  }

  final Set<DisposalHandlerMethod> handlers = HashSet<DisposalHandlerMethod>(
    equals: equalsHelper,
    hashCode: (DisposalHandlerMethod handler) {
      return Object.hash(handler.disposableType.hashCode, handler.tag.hashCode);
    },
  );

  final Iterable<DisposalHandlerMethod> methods = modules
      .map(
        (ModuleAnnotation module) =>
            module.moduleElement.getDisposalHandlerMethods(),
      )
      .expand((List<DisposalHandlerMethod> methods) => methods)
      // if module is used several times, just make unique methods
      .toSet()
      .toList();

  for (final DisposalHandlerMethod method in methods) {
    check(handlers.add(method), () {
      final List<DisposalHandlerMethod> registeredHandlers =
          <DisposalHandlerMethod>[
        methods.firstWhere(
          (DisposalHandlerMethod handler) => equalsHelper(handler, method),
        ),
        method
      ];

      final String places = registeredHandlers
          .map(
            (DisposalHandlerMethod handler) =>
                '${handler.element.enclosingElement.name}.${handler.element.name}',
          )
          .join(', ');
      return buildErrorMessage(
        error: JuggerErrorId.multiple_disposal_handlers_for_type,
        message:
            'Disposal handler for ${method.disposableType.getName()} provided multiple times: $places',
      );
    });
  }
  return handlers.toList(growable: false);
}

/// Wrapper class for component builder classes that are annotated by
/// [ComponentBuilder].
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

abstract class BaseComponentAnnotation implements Annotation {
  List<DependencyAnnotation> get dependencies;

  List<ModuleAnnotation> get modules;

  DartType? get builder;
}

/// Wrapper class for component annotation.
class ComponentAnnotation implements BaseComponentAnnotation {
  const ComponentAnnotation({
    required this.modules,
    required this.dependencies,
    required this.builder,
  });

  /// Returns the modules that are included to the component.
  @override
  final List<ModuleAnnotation> modules;

  /// Returns the another components that are included to the component as
  /// dependencies.
  @override
  final List<DependencyAnnotation> dependencies;

  /// Component builder type, it is not guaranteed that the type is a valid
  /// class, you need to make sure before using it.
  @override
  final DartType? builder;
}

class SubcomponentAnnotation implements BaseComponentAnnotation {
  SubcomponentAnnotation({
    required this.modules,
    required this.builder,
  });

  @override
  final List<DependencyAnnotation> dependencies =
      const <DependencyAnnotation>[];

  @override
  final List<ModuleAnnotation> modules;

  @override
  final DartType? builder;
}

/// Wrapper class for provide annotation.
class ProvideAnnotation implements Annotation {
  const ProvideAnnotation();
}

/// Wrapper class for inject annotation.
class InjectAnnotation implements Annotation {
  const InjectAnnotation();
}

/// Wrapper class for scope annotation.
class ScopeAnnotation implements Annotation {
  const ScopeAnnotation({
    required this.type,
  });

  final DartType type;

  @override
  bool operator ==(Object o) => o is ScopeAnnotation && type == o.type;

  @override
  int get hashCode => type.hashCode;

  @override
  String toString() => type.getName();
}

/// Wrapper class for bind annotation.
class BindAnnotation implements Annotation {
  const BindAnnotation();
}

abstract class MultibindingsGroupAnnotation implements Annotation {
  const MultibindingsGroupAnnotation();
}

class IntoSetAnnotation implements MultibindingsGroupAnnotation {
  const IntoSetAnnotation();
}

class IntoMapAnnotation implements MultibindingsGroupAnnotation {
  const IntoMapAnnotation();
}

class SubcomponentFactoryAnnotation implements Annotation {
  const SubcomponentFactoryAnnotation();
}

class MultibindingsKeyAnnotation<K> implements Annotation {
  const MultibindingsKeyAnnotation(this.key, this.type);

  final K key;
  final DartType type;
}

class EnumAnnotation implements MultibindingsKeyAnnotation<String> {
  const EnumAnnotation(this.key, this.type);

  @override
  final String key;
  @override
  final DartType type;
}

/// Wrapper class for nonLazy annotation.
class NonLazyAnnotation implements Annotation {
  const NonLazyAnnotation();
}

/// Wrapper class for disposable annotation.
class DisposableAnnotation implements Annotation {
  DisposableAnnotation(this.strategy);

  final DisposalStrategy strategy;
}

/// Wrapper class for disposalHandler annotation.
class DisposalHandlerAnnotation implements Annotation {
  const DisposalHandlerAnnotation();
}

/// Wrapper class for componentBuilder annotation.
class ComponentBuilderAnnotation implements Annotation {
  const ComponentBuilderAnnotation();
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

extension ProvideMethodExt on ProvideMethod {
  bool get _hasScoped => annotations.anyInstance<ScopeAnnotation>();

  bool get hasDisposable => annotations.anyInstance<DisposableAnnotation>();

  bool get isDisposable => _hasScoped && hasDisposable;
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
    methodElement.returnType.checkUnsupportedType();
    return StaticProvideMethod._(
      element: methodElement,
      annotations: getAnnotations(methodElement),
      tag: methodElement.getQualifierAnnotationOrNull()?.tag,
    );
  }
}

/// Static method of dispose graph object.
class DisposalHandlerMethod extends ModuleMethod {
  DisposalHandlerMethod._({
    required MethodElement element,
    required List<Annotation> annotations,
    required this.tag,
    required this.disposableType,
  }) : super(element: element, annotations: annotations);

  /// Create method from element and validate.
  factory DisposalHandlerMethod.fromMethodElement(MethodElement element) {
    check(
      element.parameters.length == 1,
      () => buildErrorMessage(
        error: JuggerErrorId.invalid_handler_method,
        message:
            'Method ${element.enclosingElement.name}.${element.name} annotated with ${j.disposalHandler.runtimeType} must have one parameter.',
      ),
    );

    final DartType parameterType = element.parameters.first.type;
    parameterType.checkUnsupportedType();
    return DisposalHandlerMethod._(
      element: element,
      annotations: getAnnotations(element),
      tag: element.getQualifierAnnotationOrNull()?.tag,
      disposableType: parameterType,
    );
  }

  final Tag? tag;
  final DartType disposableType;
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
    final InterfaceElement? typeElement =
        parameterType.element?.castToOrThrow<InterfaceElement>();

    final bool isSupertype = typeElement!.allSupertypes.any(
      (InterfaceType interfaceType) => interfaceType == element.returnType,
    );

    check(
      isSupertype,
      () => buildErrorMessage(
        error: JuggerErrorId.bind_wrong_type,
        message:
            'Method ${moduleElement.name}.${element.name} parameter type must be assignable to the return type.',
      ),
    );

    final Element rawParameter = element.parameters[0].type.element!;
    element.returnType.checkUnsupportedType();
    return AbstractProvideMethod._(
      assignableType: rawParameter.castToOrThrow<InterfaceElement>().thisType,
      element: element,
      annotations: getAnnotations(element),
      tag: element.getQualifierAnnotationOrNull()?.tag,
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

/// Wrapper for method of dispose component.
/// ```dart
/// @Component()
/// abstract class AppComponent {
///   Future<void> dispose(); <---
/// }
/// ```
class DisposeMethod extends ComponentMethod {
  const DisposeMethod({
    required this.element,
  });

  final MethodElement element;
}

class SubcomponentFactoryMethod extends ComponentMethod {
  SubcomponentFactoryMethod(this.element);

  final MethodElement element;

  late final ParameterElement _builderParameter = () {
    check(
      element.parameters.length == 1,
      () => buildErrorMessage(
        error: JuggerErrorId.invalid_subcomponent_factory,
        message: 'Subcomponent factory method must have 1 parameter. And it '
            'should be a subcomponent builder',
      ),
    );
    final ParameterElement parameter = element.parameters.first;

    String baseMessage(String reason) {
      final StringBuffer messageBuilder = StringBuffer()
        ..write('Method ')
        ..write(parameter.enclosingElement?.enclosingElement?.name)
        ..write('.')
        ..write(parameter.enclosingElement?.name)
        ..write(' is invalid. ')
        ..write(reason);

      return messageBuilder.toString();
    }

    check(
      !parameter.isNamed,
      () => buildErrorMessage(
        error: JuggerErrorId.wrong_subcomponent_factory,
        message: baseMessage('Named parameter not allowed.'),
      ),
    );
    check(
      !parameter.isOptional,
      () => buildErrorMessage(
        error: JuggerErrorId.wrong_subcomponent_factory,
        message: baseMessage('Optional parameter not allowed.'),
      ),
    );
    check(
      parameter.type.nullabilitySuffix == NullabilitySuffix.none,
      () => buildErrorMessage(
        error: JuggerErrorId.wrong_subcomponent_factory,
        message: baseMessage('Nullable parameter not allowed.'),
      ),
    );
    return parameter;
  }();

  late final ClassElement _builderClass = () {
    final Element? builderElement = _builderParameter.type.element;
    check(
      builderElement?.getAnnotationOrNull<ComponentBuilderAnnotation>() != null,
      () => buildErrorMessage(
        error: JuggerErrorId.invalid_subcomponent_factory,
        message: "Class ${builderElement?.name} must be annotated with "
            "@componentBuilder annotation.",
      ),
    );
    final ClassElement classElement = builderElement.requiredType();
    final MethodElement? buildMethod = classElement.methods
        .firstWhereOrNull((MethodElement element) => element.name == 'build');
    checkUnexpected(buildMethod != null, () => 'build method not found.');

    check(
      element.returnType == buildMethod!.returnType,
      () => buildErrorMessage(
        error: JuggerErrorId.wrong_subcomponent_factory,
        message: 'Subcomponent builder must return the same type as the method.'
            '\nMethod return: ${element.returnType},\n'
            'Builder return: ${buildMethod.returnType}.',
      ),
    );
    return classElement;
  }();

  ParameterElement resolveBuilderParameter() => _builderParameter;

  ClassElement resolveBuilderParameterClass() => _builderClass;
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
