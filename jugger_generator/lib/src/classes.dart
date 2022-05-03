import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:jugger_generator/src/utils.dart';
import 'package:jugger_generator/src/visitors.dart';

import 'tag.dart';

class Component {
  Component({
    required this.element,
    required this.annotations,
    required this.methods,
  });

  final ClassElement element;
  final List<Annotation> annotations;
  final List<MemberInjectorMethod> methods;

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
      .map((ModuleAnnotation module) {
        final ProvidesVisitor v = ProvidesVisitor();
        module.moduleElement.visitChildren(v);
        return v.methods;
      })
      .expand((List<Method> l) => l)
      .toList();

  late final List<MethodElement> _provideMethods = () {
    final ProvideMethodVisitor v = ProvideMethodVisitor();
    element.visitChildren(v);
    return v.methods
      ..sort((MethodElement a, MethodElement b) => a.name.compareTo(b.name));
  }();

  late final List<PropertyAccessorElement> _provideProperties = () {
    final ProvidePropertyVisitor v = ProvidePropertyVisitor();
    element.visitChildren(v);
    return v.properties
      ..sort((PropertyAccessorElement a, PropertyAccessorElement b) =>
          a.name.compareTo(b.name));
  }();

  // endregion private

  List<ModuleAnnotation> get modules => _modules;

  List<DependencyAnnotation> get dependencies => _dependencies;

  List<Method> get modulesProvideMethods => _modulesProvideMethods;

  List<MethodElement> get provideMethods => _provideMethods;

  List<PropertyAccessorElement> get provideProperties => _provideProperties;
}

class ComponentBuilder {
  ComponentBuilder({
    required this.element,
    required this.componentClass,
    required this.methods,
  });

  final ClassElement element;
  final ClassElement componentClass;

  final List<MethodElement> methods;

  late final List<ParameterElement> _buildInstanceFields =
      parameters.map((ComponentBuilderParameter p) => p.parameter).toList();

  late final List<ComponentBuilderParameter> _parameters = methods
      .expand<ParameterElement>((MethodElement methodElement) {
        return methodElement.parameters;
      })
      .map((ParameterElement p) => ComponentBuilderParameter(parameter: p))
      .toList();

  List<ComponentBuilderParameter> get parameters => _parameters;

  List<ParameterElement> get buildInstanceFields => _buildInstanceFields;
}

class ComponentBuilderParameter {
  const ComponentBuilderParameter({
    required this.parameter,
  });

  final ParameterElement parameter;

  @override
  String toString() {
    return parameter.type.getName();
  }

  String get fieldName {
    return '_${uncapitalize(parameter.type.getName())}';
  }
}

abstract class Annotation {}

class ComponentAnnotation implements Annotation {
  const ComponentAnnotation({
    required this.element,
    required this.modules,
    required this.dependencies,
  });

  final Element element;
  final List<ModuleAnnotation> modules;
  final List<DependencyAnnotation> dependencies;
}

class ProvideAnnotation implements Annotation {}

class InjectAnnotation implements Annotation {}

class SingletonAnnotation implements Annotation {}

class BindAnnotation implements Annotation {}

class NonLazyAnnotation implements Annotation {}

class ComponentBuilderAnnotation implements Annotation {
  const ComponentBuilderAnnotation(this.element);

  final ClassElement element;
}

class ModuleAnnotation implements Annotation {
  const ModuleAnnotation({
    required this.moduleElement,
    required this.includes,
  });

  /// annotated module class
  final ClassElement moduleElement;
  final List<ModuleAnnotation> includes;

  bool get isAbstract => moduleElement.isAbstract;
}

class DependencyAnnotation implements Annotation {
  const DependencyAnnotation({required this.element});

  final ClassElement element;
}

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

class Method {
  Method(this.element, this.annotations);

  final MethodElement element;
  final List<Annotation> annotations;

  late final QualifierAnnotation? _qualifierAnnotation = () {
    final Annotation? annotation = annotations
        .firstWhereOrNull((Annotation a) => a is QualifierAnnotation);
    return annotation is QualifierAnnotation ? annotation : null;
  }();

  late final Tag? _tag = _qualifierAnnotation?.tag;

  Tag? get tag => _tag;
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

class MyComponent {
  const MyComponent(this.classElement, this.componentAnnotation);

  final ClassElement classElement;
  final ComponentAnnotation componentAnnotation;

  String get name => classElement.name;
}

class InjectedConstructor {
  const InjectedConstructor(this.element);

  final ConstructorElement element;

  List<Annotation> get annotations {
    return getAnnotations(element);
  }

  bool get isInjected => annotations
      .any((Annotation annotation) => annotation is InjectAnnotation);
}
