import 'package:analyzer/dart/element/element.dart';
import 'package:jugger_generator/src/utils.dart';
import 'package:jugger_generator/src/visitors.dart';
import 'package:meta/meta.dart';

class Component {
  const Component({
    @required this.element,
    @required this.annotations,
    @required this.methods,
  });

  final ClassElement element;
  final List<Annotation> annotations;
  final List<MemberInjectorMethod> methods;

  List<ModuleAnnotation> get modules {
    return getComponentAnnotation()?.modules;
  }

  List<DependencyAnnotation> get dependencies {
    return getComponentAnnotation()?.dependencies;
  }

  ComponentAnnotation getComponentAnnotation() {
    final ComponentAnnotation annotation =
        annotations.firstWhere((Annotation a) {
      return a is ComponentAnnotation;
    });
    return annotation;
  }

  List<Method> get provideMethods {
    return modules.map((ModuleAnnotation module) {
      final ProvidesVisitor v = ProvidesVisitor();
      module.element.visitChildren(v);
      return v.methods;
    }).expand((List<Method> l) {
      return l;
    }).toList();
  }

  List<ParameterElement> buildInstanceFields(
      ComponentBuilder componentBuilder) {
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
    return v.methods;
  }
}

class ComponentBuilder {
  const ComponentBuilder({
    @required this.element,
    @required this.componentClass,
    @required this.methods,
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
    @required this.parameter,
  });

  final ParameterElement parameter;

  @override
  String toString() {
    return parameter.type.name;
  }

  String get fieldName {
    return '_${uncapitalize(parameter.type.name)}';
  }
}

abstract class Annotation {}

class ComponentAnnotation implements Annotation {
  const ComponentAnnotation(
      {@required this.element,
      @required this.modules,
      @required this.dependencies});

  final Element element;
  final List<ModuleAnnotation> modules;
  final List<DependencyAnnotation> dependencies;
}

class ProvideAnnotation implements Annotation {}

class InjectAnnotation implements Annotation {}

class SingletonAnnotation implements Annotation {}

class BindAnnotation implements Annotation {}

class ComponentBuilderAnnotation implements Annotation {
  const ComponentBuilderAnnotation(this.element);

  final ClassElement element;
}

class ModuleAnnotation implements Annotation {
  const ModuleAnnotation(this.element);

  final ClassElement element;
}

class DependencyAnnotation implements Annotation {
  const DependencyAnnotation({@required this.element});

  final ClassElement element;
}

class NamedAnnotation implements Annotation {
  const NamedAnnotation({
    @required this.element,
    @required this.name,
  });

  final ClassElement element;
  final String name;
}

class Method {
  const Method(this.element, this.annotations);

  final MethodElement element;

  final List<Annotation> annotations;

  NamedAnnotation get _namedAnnotation => annotations
      .firstWhere((Annotation a) => a is NamedAnnotation, orElse: () => null);

  String get named => _namedAnnotation?.name;
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
