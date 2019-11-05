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
    final ComponentAnnotation annotation =
        annotations.firstWhere((Annotation a) {
      return a is ComponentAnnotation;
    });
    return annotation?.modules;
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
}

abstract class Annotation {}

class ComponentAnnotation implements Annotation {
  const ComponentAnnotation({this.element, this.modules});

  final Element element;
  final List<ModuleAnnotation> modules;
}

class ProvideAnnotation implements Annotation {}

class InjectAnnotation implements Annotation {}

class SingletonAnnotation implements Annotation {}

class BindAnnotation implements Annotation {}

class ModuleAnnotation implements Annotation {
  const ModuleAnnotation(this.element);

  final ClassElement element;
}

class Method {
  const Method(this.element, this.annotations);

  final MethodElement element;

  final List<Annotation> annotations;
}

class MemberInjectorMethod {
  const MemberInjectorMethod(this.element);

  final MethodElement element;
}

class InjectedMember {
  const InjectedMember(this.element);

  final FieldElement element;
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
