import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';

import 'classes.dart';

ComponentAnnotation getComponentAnnotation(Element element) {
  return getAnnotations(element).firstWhere(
      (Annotation a) => a is ComponentAnnotation,
      orElse: () => null);
}

BindAnnotation getBindAnnotation(Element element) {
  return getAnnotations(element).firstWhere(
          (Annotation a) => a is BindAnnotation,
      orElse: () => null);
}

ProvideAnnotation getProvideAnnotation(Element element) {
  return getAnnotations(element).firstWhere(
          (Annotation a) => a is ProvideAnnotation,
      orElse: () => null);
}

List<Annotation> getAnnotations(Element element) {
  final List<Annotation> annotations = <Annotation>[];

  final List<ElementAnnotation> resolvedMetadata = element.metadata;

  for (int i = 0; i < resolvedMetadata.length; i++) {
    ElementAnnotation annotation = resolvedMetadata[i];
    Element valueElement = annotation.computeConstantValue()?.type?.element;

    if (valueElement == null) {
      //TODO
    } else {
      if (valueElement.name == 'Component') {
        final List<ClassElement> listValue = annotation
            .computeConstantValue()
            .getField('modules')
            .toListValue()
            .cast<DartObject>()
            .map((DartObject o) => o.toTypeValue().element as ClassElement)
            .toList();

        annotations.add(ComponentAnnotation(
            element: valueElement,
            modules: listValue.map((ClassElement c) {
              if (!c.isAbstract) {
                throw StateError(
                  'module must be abstract [${c.thisType.name}]',
                );
              }
              return ModuleAnnotation(c);
            }).toList()));
      } else if (valueElement.name == 'Provide') {
        annotations.add(ProvideAnnotation());
      } else if (valueElement.name == 'Inject') {
        annotations.add(InjectAnnotation());
      } else if (valueElement.name == 'Singleton') {
        annotations.add(SingletonAnnotation());
      } else if (valueElement.name == 'Bind') {
        annotations.add(BindAnnotation());
      }
    }
  }
  return annotations;
}

String uncapitalize(String name) {
  return name[0].toLowerCase() + name.substring(1);
}

String createElementPath(Element element) {
  return 'package:${element.source.uri.path}'.replaceFirst('/lib', '');
}
