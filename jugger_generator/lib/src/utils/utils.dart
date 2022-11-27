import 'dart:convert';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:jugger/jugger.dart';

import '../builder/session_cache.dart';
import '../errors_glossary.dart';
import '../generator/tag.dart';
import '../generator/wrappers.dart';
import '../jugger_error.dart';
import '../utils/element_ext.dart';
import 'dart_type_ext.dart';
import 'element_annotation_ext.dart';
import 'library_ext.dart';
import 'module_extractor.dart';

String generateMd5(String input) => md5.convert(utf8.encode(input)).toString();

List<Annotation> getAnnotations(Element element) {
  return sessionCache.getAnnotations(element, () => _getAnnotations(element));
}

List<Annotation> _getAnnotations(Element element) {
  final List<Annotation> annotations = <Annotation>[];

  for (int i = 0; i < element.metadata.length; i++) {
    final ElementAnnotation annotation = element.metadata[i];

    final Element? annotationElement = annotation.element;

    if (annotationElement is PropertyAccessorElement) {
      final ClassElement annotationClassElement =
          annotationElement.variable.type.element! as ClassElement;
      final bool isQualifier = annotationClassElement.metadata.isQualifier();

      if (isQualifier) {
        annotations.add(
          QualifierAnnotation(tag: _getTag(annotation, annotationClassElement)),
        );
      }
    } else if (annotationElement is ConstructorElement) {
      final InterfaceElement interface = annotationElement.enclosingElement;
      final bool isQualifier = interface.metadata.isQualifier();
      if (isQualifier) {
        annotations.add(
          QualifierAnnotation(tag: _getTag(annotation, interface)),
        );
      }
    }
  }

  final List<ElementAnnotation> resolvedMetadata = element.metadata;

  for (int i = 0; i < resolvedMetadata.length; i++) {
    final ElementAnnotation annotation = resolvedMetadata[i];
    final Element? valueElement =
        annotation.computeConstantValue()?.type?.element;

    if (valueElement == null) {
      throw UnexpectedJuggerError(
        'Unable resolve valueElement. Annotated element: $element',
      );
    } else {
      if (valueElement.metadata.isMapKey()) {
        final DartObject? field =
            annotation.computeConstantValue()?.getField('value');

        if (field == null) {
          throw JuggerError(
            buildErrorMessage(
              error: JuggerErrorId.multibindings_invalid_key,
              message: 'Unable resolve value. '
                  'Did you forget to add value field?',
            ),
          );
        }

        late final String? stringValue = field.toStringValue();
        late final int? intValue = field.toIntValue();
        late final double? doubleValue = field.toDoubleValue();
        late final bool? boolValue = field.toBoolValue();
        late final DartType? typeValue = field.toTypeValue();
        final Element? enumElement = field.type?.element;

        if (stringValue != null) {
          annotations.add(
            MultibindingsKeyAnnotation<String>(stringValue, field.type!),
          );
        } else if (intValue != null) {
          annotations
              .add(MultibindingsKeyAnnotation<int>(intValue, field.type!));
        } else if (doubleValue != null) {
          annotations.add(
            MultibindingsKeyAnnotation<double>(doubleValue, field.type!),
          );
        } else if (boolValue != null) {
          annotations
              .add(MultibindingsKeyAnnotation<bool>(boolValue, field.type!));
        } else if (typeValue != null) {
          annotations.add(
            MultibindingsKeyAnnotation<DartType>(typeValue, field.type!),
          );
        } else if (enumElement != null) {
          check(
            enumElement is EnumElement,
            () => buildErrorMessage(
              error: JuggerErrorId.multibindings_unsupported_key_type,
              message: 'Type $field unsupported.',
            ),
          );
          final String enumValue = annotation
                  .computeConstantValue()
                  ?.getField('value')
                  ?.getField('_name')
                  ?.toStringValue() ??
              (throw JuggerError(
                buildUnexpectedErrorMessage(
                  message: 'Unable resolve name of enum key!',
                ),
              ));

          annotations.add(EnumAnnotation(enumValue, field.type!));
        } else {
          throw JuggerError(
            buildErrorMessage(
              error: JuggerErrorId.multibindings_unsupported_key_type,
              message: 'Type $field unsupported.',
            ),
          );
        }
        continue;
      } else if (valueElement.metadata.isScope()) {
        annotations.add(ScopeAnnotation(type: valueElement.tryGetType()));
        continue;
      }

      if (!annotation.element!.library!.isJuggerLibrary) {
        continue;
      }

      if (valueElement.name == 'Component' ||
          valueElement.name == 'Subcomponent') {
        final List<ClassElement> modules = getClassListFromField(
          annotation,
          'modules',
        );

        late final List<DependencyAnnotation> dependencies = () {
          final List<ClassElement> dependencies = getClassListFromField(
            annotation,
            'dependencies',
          );
          check(
            !dependencies.contains(element),
            () => buildErrorMessage(
              error: JuggerErrorId.component_depend_himself,
              message: 'A component ${element.name} cannot depend on himself.',
            ),
          );
          return dependencies.map((ClassElement c) {
            check(
              c.getComponentAnnotationOrNull() != null,
              () => buildErrorMessage(
                error: JuggerErrorId.invalid_component_dependency,
                message:
                    'Dependency ${c.name} is not allowed, only other components are allowed.',
              ),
            );
            return DependencyAnnotation(element: c);
          }).toList();
        }();

        final List<ModuleAnnotation> modulesAnnotations =
            modules.map((ClassElement moduleDep) {
          return ModuleExtractor().getModuleAnnotationOfModuleClass(moduleDep);
        }).toList();

        List<ModuleAnnotation> getModules(ModuleAnnotation module) {
          if (module.includes.isEmpty) {
            return <ModuleAnnotation>[];
          }

          //check repeated annotation from includes field
          checkUniqueClasses(
            module.includes
                .map((ModuleAnnotation annotation) => annotation.moduleElement),
          );
          return module.includes +
              module.includes
                  .expand((ModuleAnnotation module) => getModules(module))
                  .toList(growable: false);
        }

        final List<ModuleAnnotation> allModules = modulesAnnotations
            .expand((ModuleAnnotation module) {
              final List<ModuleAnnotation> modules = getModules(module);
              return List<ModuleAnnotation>.from(modules + module.includes)
                ..add(module);
            })
            .toSet()
            .toList(growable: false);

        // region : check repeated annotation from modules field
        final Map<InterfaceType, List<ModuleAnnotation>> groupedAnnotations =
            modulesAnnotations.groupListsBy(
          (ModuleAnnotation annotation) => annotation.moduleElement.thisType,
        );
        for (final List<ModuleAnnotation> group in groupedAnnotations.values) {
          check(
            group.length == 1,
            () => buildErrorMessage(
              error: JuggerErrorId.repeated_modules,
              message:
                  'Repeated modules [${group.first.moduleElement.name}] not allowed.',
            ),
          );
        }
        // endregion

        final DartType? builderType = annotation
            .computeConstantValue()
            ?.getField('builder')
            ?.toTypeValue();

        if (builderType != null) {
          final ComponentBuilderAnnotation? componentBuilderAnnotation =
              builderType.element
                  ?.getAnnotationOrNull<ComponentBuilderAnnotation>();

          check(
            componentBuilderAnnotation != null,
            () => buildErrorMessage(
              error: JuggerErrorId.wrong_component_builder,
              message: '${builderType.getName()} is not component builder.',
            ),
          );
        }

        final DartType? notNullableBuilderType =
            builderType?.element?.tryGetType();

        switch (valueElement.name) {
          case 'Component':
            {
              annotations.add(
                ComponentAnnotation(
                  builder: notNullableBuilderType,
                  modules: allModules.toList(),
                  dependencies: dependencies,
                ),
              );
              break;
            }
          case 'Subcomponent':
            {
              annotations.add(
                SubcomponentAnnotation(
                  builder: notNullableBuilderType,
                  modules: allModules.toList(),
                ),
              );
              break;
            }
          default:
            {
              throw UnexpectedJuggerError(
                'Unexpected annotation ${valueElement.name}',
              );
            }
        }
      } else if (valueElement.name == provides.runtimeType.toString()) {
        annotations.add(const ProvideAnnotation());
      } else if (valueElement.name == inject.runtimeType.toString()) {
        annotations.add(const InjectAnnotation());
      } else if (valueElement.name == module.runtimeType.toString()) {
        annotations.add(
          ModuleExtractor().getModuleAnnotationOfModuleClass(element),
        );
      } else if (valueElement.name == binds.runtimeType.toString()) {
        annotations.add(const BindAnnotation());
      } else if (valueElement.name == componentBuilder.runtimeType.toString()) {
        annotations.add(const ComponentBuilderAnnotation());
      } else if (valueElement.name ==
          subcomponentFactory.runtimeType.toString()) {
        annotations.add(const SubcomponentFactoryAnnotation());
      } else if (valueElement.name == nonLazy.runtimeType.toString()) {
        annotations.add(const NonLazyAnnotation());
      } else if (valueElement.name == disposable.runtimeType.toString()) {
        final int enumIndex = annotation
            .computeConstantValue()!
            .getField('strategy')!
            .getField('index')!
            .toIntValue()!;
        annotations
            .add(DisposableAnnotation(DisposalStrategy.values[enumIndex]));
      } else if (valueElement.name == disposalHandler.runtimeType.toString()) {
        annotations.add(const DisposalHandlerAnnotation());
      } else if (valueElement.name == intoSet.runtimeType.toString()) {
        annotations.add(const IntoSetAnnotation());
      } else if (valueElement.name == intoMap.runtimeType.toString()) {
        annotations.add(const IntoMapAnnotation());
      }
    }
  }
  return annotations;
}

Tag _getTag(
  ElementAnnotation annotation,
  InterfaceElement annotationClassElement,
) {
  if (annotationClassElement.name == 'Named') {
    final String? stringName =
        annotation.computeConstantValue()!.getField('name')!.toStringValue();
    checkUnexpected(
      stringName != null,
      () => buildUnexpectedErrorMessage(
        message: 'Unable get name of Named',
      ),
    );
    final String id = stringName!;
    return Tag(uniqueId: id, originalId: id);
  } else {
    final String originalId = annotationClassElement.name;
    final String uniqueId =
        '${annotationClassElement.library.source.shortName}:$originalId}';
    return Tag(uniqueId: uniqueId, originalId: originalId);
  }
}

void checkUniqueClasses(Iterable<ClassElement> classes) {
  final Map<InterfaceType, List<ClassElement>> groupedAnnotations =
      classes.groupListsBy((ClassElement annotation) => annotation.thisType);
  for (final List<ClassElement> group in groupedAnnotations.values) {
    check(
      group.length == 1,
      () => buildErrorMessage(
        error: JuggerErrorId.repeated_modules,
        message: 'Repeated modules [${group.first.name}] not allowed.',
      ),
    );
  }
}

List<ClassElement> getClassListFromField(
  ElementAnnotation annotation,
  String name,
) {
  final List<ClassElement>? result = annotation
      .computeConstantValue()
      ?.getField(name)
      ?.toListValue()
      ?.cast<DartObject>()
      // ignore: avoid_as
      .map((DartObject o) => o.toTypeValue()!.element! as ClassElement)
      .toList();
  checkUnexpected(
    result != null,
    () => buildUnexpectedErrorMessage(
      message: 'unable get $name from annotation',
    ),
  );
  return result!;
}

String uncapitalize(String name) {
  return name[0].toLowerCase() + name.substring(1);
}

String capitalize(String name) => name[0].toUpperCase() + name.substring(1);

String createElementPath(Element element) {
  return 'package:${element.source!.uri.path}'.replaceFirst('/lib', '');
}

bool isCore(Element element) {
  return element.librarySource!.fullName.startsWith('dart:');
}

bool isFlutterCore(Element element) {
  return element.librarySource!.fullName.startsWith('/flutter');
}

String createClassNameWithPath(ClassElement element) {
  return '${element.name} ${element.library.identifier}';
}

// ignore: avoid_positional_boolean_parameters
void check(bool condition, String Function() message) {
  if (!condition) {
    throw JuggerError(message.call());
  }
}

// ignore: avoid_positional_boolean_parameters
void checkUnexpected(bool condition, String Function() message) {
  if (!condition) {
    throw UnexpectedJuggerError(message.call());
  }
}
