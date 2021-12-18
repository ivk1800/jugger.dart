import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:jugger_generator/src/utils.dart';
import 'package:jugger_generator/src/visitors.dart';

class Component {
  const Component({
    required this.element,
    required this.annotations,
    required this.methods,
  });

  final ClassElement element;
  final List<Annotation> annotations;
  final List<MemberInjectorMethod> methods;

  List<ModuleAnnotation> get modules =>
      getComponentAnnotation()?.modules ?? List<ModuleAnnotation>.empty();

  List<DependencyAnnotation> get dependencies =>
      getComponentAnnotation()?.dependencies ??
      List<DependencyAnnotation>.empty();

  ComponentAnnotation? getComponentAnnotation() {
    final Annotation? annotation = annotations
        .firstWhereOrNull((Annotation a) => a is ComponentAnnotation);
    return annotation is ComponentAnnotation ? annotation : null;
  }

  List<Method> get provideMethods {
    return modules.map((ModuleAnnotation module) {
      final ProvidesVisitor v = ProvidesVisitor();
      module.moduleElement.visitChildren(v);
      return v.methods;
    }).expand((List<Method> l) {
      return l;
    }).toList();
  }

  List<ParameterElement> buildInstanceFields(
      ComponentBuilder? componentBuilder) {
    if (componentBuilder == null) {
      return <ParameterElement>[];
    }
    return componentBuilder.parameters
        .map((ComponentBuilderParameter p) => p.parameter)
        .toList();
  }

  List<MethodElement> get provideMethod {
    final ProvideMethodVisitor v = ProvideMethodVisitor();
    element.visitChildren(v);
    return v.methods
      ..sort((MethodElement a, MethodElement b) => a.name.compareTo(b.name));
  }

  List<PropertyAccessorElement> get provideProperties {
    final ProvidePropertyVisitor v = ProvidePropertyVisitor();
    element.visitChildren(v);
    return v.properties
      ..sort((PropertyAccessorElement a, PropertyAccessorElement b) =>
          a.name.compareTo(b.name));
  }
}

class ComponentBuilder {
  const ComponentBuilder({
    required this.element,
    required this.componentClass,
    required this.methods,
  });

  final ClassElement element;
  final ClassElement componentClass;

  final List<MethodElement> methods;

  List<ComponentBuilderParameter> get parameters {
    return methods
        .expand<ParameterElement>((MethodElement methodElement) {
          return methodElement.parameters;
        })
        .map((ParameterElement p) => ComponentBuilderParameter(parameter: p))
        .toList();
  }
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
  const ComponentAnnotation(
      {required this.element,
      required this.modules,
      required this.dependencies});

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
  });

  /// annotated module class
  final ClassElement moduleElement;

  bool get isAbstract => moduleElement.isAbstract;
}

class DependencyAnnotation implements Annotation {
  const DependencyAnnotation({required this.element});

  final ClassElement element;
}

class NamedAnnotation implements Annotation {
  const NamedAnnotation({
    required this.element,
    required this.name,
  });

  final ClassElement element;
  final String name;
}

class Method {
  const Method(this.element, this.annotations);

  final MethodElement element;

  final List<Annotation> annotations;

  NamedAnnotation? get _namedAnnotation {
    final Annotation? annotation =
        annotations.firstWhereOrNull((Annotation a) => a is NamedAnnotation);
    return annotation is NamedAnnotation ? annotation : null;
  }

  String? get named => _namedAnnotation?.name;
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
