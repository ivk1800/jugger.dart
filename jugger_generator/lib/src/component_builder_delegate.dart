import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:jugger/jugger.dart' as jugger;
import 'package:jugger_generator/src/class_element_ext.dart';
import 'package:jugger_generator/src/dart_type_ext.dart';
import 'package:jugger_generator/src/utils.dart';

import 'check_unused_providers.dart';
import 'classes.dart' as j;
import 'component_context.dart';
import 'global_config.dart';
import 'jugger_error.dart';
import 'messages.dart';
import 'tag.dart';
import 'visitors.dart';

class ComponentBuilderDelegate {
  ComponentBuilderDelegate({
    required this.globalConfig,
  });

  final GlobalConfig globalConfig;
  late ComponentContext _componentContext;
  late Allocator _allocator;
  late DartType _componentType;
  final List<String> _logs = <String>[];
  final Expression _overrideAnnotationExpression =
      const CodeExpression(Code('override'));

  static const List<String> Ignores = <String>[
    'ignore_for_file: implementation_imports',
    'ignore_for_file: prefer_const_constructors',
    'ignore_for_file: always_specify_types',
    'ignore_for_file: directives_ordering',
    'ignore_for_file: non_constant_identifier_names',
  ];

  Future<String> buildOutput(BuildStep buildStep) async {
    try {
      return await _buildOutput(buildStep);
    } catch (e) {
      final String message = '${_logs.join('\n')}\n$e';
      print('\x1B[94m$message\x1B[0m');
      print((e as Error).stackTrace);
      rethrow;
    }
  }

  Future<String> _buildOutput(BuildStep buildStep) async {
    final Resolver resolver = buildStep.resolver;

    if (await resolver.isLibrary(buildStep.inputId)) {
      _allocator = Allocator.simplePrefixing();

      final LibraryElement lib = await buildStep.inputLibrary;

      final ComponentBuildersVisitor componentBuildersVisitor =
          ComponentBuildersVisitor();
      lib.visitChildren(componentBuildersVisitor);

      final ComponentsVisitor visitor = ComponentsVisitor();
      lib.visitChildren(visitor);

      final LibraryBuilder target = LibraryBuilder();

      _generateComponentBuilders(
          target, lib, componentBuildersVisitor.componentBuilders);

      for (int i = 0; i < visitor.components.length; i++) {
        final j.Component component = visitor.components[i];
        _componentType = component.element.thisType;

        final j.ComponentBuilder? componentBuilder = componentBuildersVisitor
            .componentBuilders
            .firstWhereOrNull((j.ComponentBuilder b) {
          return b.componentClass.name == component.element.name;
        });

        _componentContext = ComponentContext.fromComponent(
          component: component,
          componentBuilder: componentBuilder,
        );
        _logs.clear();

        target.body.add(Class((ClassBuilder classBuilder) {
          classBuilder.fields.addAll(
            _buildProvidesFields(
              _componentContext.dependencies,
              _componentContext,
              _allocator,
            ),
          );
          classBuilder.fields.addAll(_buildConstructorFields(componentBuilder));
          _log('build for component: ${component.element.toNameWithPath()}');
          classBuilder.methods.addAll(_buildProvideMethods(_componentContext));
          classBuilder.methods
              .addAll(_buildProvideProperties(_componentContext));

          if (hasNonLazyProviders()) {
            classBuilder.methods
                .add(_buildInitNonLazyMethod(_componentContext));
          }

          classBuilder.methods.addAll(_buildMembersInjectorMethods(
              component.memberInjectors, classBuilder, _componentContext));

          classBuilder.implements
              .add(Reference(component.element.name, createElementPath(lib)));

          classBuilder.constructors.add(_buildConstructor(componentBuilder));

          classBuilder..name = _createComponentName(component.element.name);
        }));
      }

      final String fileText =
          target.build().accept(DartEmitter(allocator: _allocator)).toString();

      if (globalConfig.checkUnusedProviders) {
        checkUnusedProviders(fileText);
      }

      final String finalFileText = fileText.isEmpty
          ? ''
          : '${Ignores.map((String line) => '// $line').join('\n')}\n$fileText';
      return DartFormatter().format(finalFileText);
    }

    return '';
  }

  void _generateComponentBuilders(LibraryBuilder target, LibraryElement lib,
      List<j.ComponentBuilder> componentBuilders) {
    for (int i = 0; i < componentBuilders.length; i++) {
      final j.ComponentBuilder componentBuilder = componentBuilders[i];

      target.body.add(Class((ClassBuilder classBuilder) {
        classBuilder.name =
            '${_createComponentName(componentBuilder.componentClass.name)}Builder';

        classBuilder.implements.add(
            Reference(componentBuilder.element.name, createElementPath(lib)));
        classBuilder.methods
            .addAll(componentBuilder.methods.map((MethodElement m) {
          return Method((MethodBuilder b) {
            b.annotations.add(_overrideAnnotationExpression);
            b.name = m.name;
            b.returns = Reference(m.returnType.getName(),
                createElementPath(m.returnType.element!));
            b.requiredParameters.addAll(m.parameters.map((ParameterElement pe) {
              return Parameter((ParameterBuilder parameterBuilder) {
                parameterBuilder.name = pe.name;
                parameterBuilder.type = refer(_allocateTypeName(pe.type));
              });
            }));

            b.body = Block((BlockBuilder b) {
              if (m.name == 'build') {
                final Iterable<Expression> map = componentBuilder.parameters
                    .map((j.ComponentBuilderParameter parameter) {
                  final Tag? tag =
                      parameter.parameter.enclosingElement!.getQualifierTag();
                  final CodeExpression codeExpression =
                      CodeExpression(Block.of(<Code>[
                    Code('_${_generateFieldName(
                      parameter.parameter._tryGetType(),
                      tag?._toAssignTag(),
                    )}!'),
                  ]));
                  return codeExpression;
                });

                final List<Code> assertCodes = componentBuilder.parameters
                    .map((j.ComponentBuilderParameter parameter) {
                  final Tag? tag =
                      parameter.parameter.enclosingElement!.getQualifierTag();
                  return Code('assert(_${_generateFieldName(
                    parameter.parameter.type,
                    tag?._toAssignTag(),
                  )} != null) ');
                }).toList();

                for (Code value in assertCodes) {
                  b.addExpression(CodeExpression(value));
                }

                final Expression newInstance = refer(
                        '${_createComponentName(m.returnType.getName())}._create')
                    .newInstance(map);

                b.addExpression(CodeExpression(Block.of(<Code>[
                  const Code('return '),
                  newInstance.code,
                ])));
              } else {
                final j.ComponentBuilderParameter p =
                    j.ComponentBuilderParameter(parameter: m.parameters[0]);
                final Tag? tag =
                    p.parameter.enclosingElement!.getQualifierTag();
                b.addExpression(CodeExpression(Block.of(<Code>[
                  Code('_${_generateFieldName(
                    p.parameter.type,
                    tag?._toAssignTag(),
                  )} = ${p.parameter.name}; return this'),
                ])));
              }
            });
          });
        }));
        classBuilder.fields.addAll(componentBuilder.parameters
            .map((j.ComponentBuilderParameter parameter) {
          return Field((FieldBuilder b) {
            b.type = refer('${_allocateTypeName(parameter.parameter.type)}?');
            final Tag? tag =
                parameter.parameter.enclosingElement!.getQualifierTag();
            b.name = '_${_generateFieldName(
              parameter.parameter.type,
              tag?._toAssignTag(),
            )}';
          });
        }));
      }));
    }
  }

  String _createComponentName(String name) {
    if (!globalConfig.removeInterfacePrefixFromComponentName ||
        name.length == 1) {
      return 'Jugger$name';
    }

    final String nextChar = name[1];
    if (name.startsWith('I') && nextChar == nextChar.toUpperCase()) {
      return 'Jugger${name.substring(1, name.length)}';
    }

    return 'Jugger$name';
  }

  Iterable<Dependency> _filterDependenciesForFields(
      List<Dependency> dependencies) {
    return dependencies.where((Dependency dependency) {
      final ClassElement typeElement = dependency.type.element as ClassElement;
      final bool isCurrentComponent =
          getComponentAnnotation(typeElement) != null &&
              dependency.type == _componentType;
      return !isCurrentComponent;
    });
  }

  List<Field> _buildProvidesFields(
    List<Dependency> dependencies,
    ComponentContext _componentContext,
    Allocator allocator,
  ) {
    final List<Field> fields = <Field>[];

    final Iterable<Dependency> filteredDependencies =
        _filterDependenciesForFields(dependencies);

    for (Dependency dependency in filteredDependencies) {
      check(
        !dependency.type.isProvider,
        () => providerNotAllowed(dependency.type),
      );

      final ProviderSource? provider =
          _componentContext.findProvider(dependency.type, dependency.tag);

      if (provider == null && dependency.tag != null) {
        throw JuggerError(
          notProvided(dependency.type, dependency.tag),
        );
      }

      if (!(provider is BuildInstanceSource) &&
          !(provider is AnotherComponentSource)) {
        fields.add(Field((FieldBuilder b) {
          final Tag? tag = dependency.tag;
          b.name = '_${_generateFieldName(
            dependency.type,
            tag?._toAssignTag(),
          )}Provider';

          final String generic = allocator.allocate(
            refer(_allocateDependencyTypeName(dependency)),
          );
          b.late = true;
          b.modifier = FieldModifier.final$;

          final ProviderSource? provider =
              _componentContext.findProvider(dependency.type, tag);

          if (provider is ModuleSource) {
            b.assignment = _buildProviderFromMethodCode(
              provider.method.element,
            );
          } else {
            final ClassElement typeElement =
                dependency.type.element as ClassElement;

            check(
              !(isCore(typeElement) || typeElement.isAbstract),
              () => notProvided(dependency.type, tag),
            );
            b.assignment = _buildProviderFromClassAssignCode(typeElement);
          }

          b.type =
              Reference('IProvider<$generic>', 'package:jugger/jugger.dart');
        }));
      }
    }

    return fields..sort((Field a, Field b) => a.name.compareTo(b.name));
  }

  String _allocateDependencyTypeName(Dependency dependency) {
    return _allocateTypeName(dependency.type);
  }

  String _allocateTypeName(DartType t) {
    check(
      t is InterfaceType,
      () => 'type [$t] not supported',
    );
    final InterfaceType type = t as InterfaceType;

    final String name = _allocator.allocate(
      Reference(
        type.element.name,
        type.element.librarySource.uri.toString(),
      ),
    );

    if (type.typeArguments.isEmpty) {
      return name;
    }

    return '$name<${type.typeArguments.map((DartType type) {
      return _allocateTypeName(type as InterfaceType);
    }).join(',')}>';
  }

  List<Method> _buildProvideProperties(ComponentContext _componentContext) {
    final List<PropertyAccessorElement> properties =
        _componentContext.component.provideProperties;

    return properties.map((PropertyAccessorElement property) {
      _log(
          'build property for: ${property.enclosingElement.name}.${property.name}');
      return Method((MethodBuilder builder) {
        final Tag? tag = property.getQualifierTag();
        builder
          ..annotations.add(_overrideAnnotationExpression)
          ..name = property.name
          ..lambda = true
          ..body = Code(_generateAssignString(
            property.returnType,
            tag,
          ))
          ..type = MethodType.getter
          ..returns = refer(_allocateTypeName(property.returnType));
      });
    }).toList();
  }

  List<Method> _buildProvideMethods(ComponentContext _componentContext) {
    final List<MethodElement> methods =
        _componentContext.component.provideMethods;
    final List<Method> newProperties = <Method>[];

    for (MethodElement method in methods) {
      _log(
          'build provide method for: ${method.enclosingElement.name}.${method.name}');
      final Method m = Method((MethodBuilder b) {
        b.annotations.add(_overrideAnnotationExpression);
        b.name = method.name;
        b.returns = refer(_allocateTypeName(method.returnType));

        final Tag? tag = method.getQualifierTag();
        final ProviderSource? providerSource =
            _componentContext.findProvider(method.returnType, tag);

        check(
          providerSource != null || method.returnType.hasInjectedConstructor(),
          () => 'not found inject constructor for [${method.runtimeType}]\n'
              '${notProvided(method.returnType, tag)}',
        );

        b.lambda = true;
        b.body = Code(
          _generateAssignString(
            method.returnType,
            tag,
          ),
        );
      });
      newProperties.add(m);
    }

    return newProperties
      ..sort((Method a, Method b) => a.name!.compareTo(b.name!));
  }

  List<Method> _buildMembersInjectorMethods(
    List<j.MemberInjectorMethod> fields,
    ClassBuilder classBuilder,
    ComponentContext _componentContext,
  ) {
    return fields.map((j.MemberInjectorMethod method) {
      final MethodBuilder builder = MethodBuilder();
      builder.name = method.element.name;
      builder.annotations.add(_overrideAnnotationExpression);
      builder.returns = const Reference('void');
      check(
        method.element.parameters.length == 1,
        () => 'method ${method.element.name} must have 1 parameter',
      );

      final ParameterElement parameterElement = method.element.parameters[0];

      final ClassElement memberElement =
          parameterElement.type.element! as ClassElement;
      builder.requiredParameters.add(Parameter((ParameterBuilder b) {
        b.name = uncapitalize(parameterElement.name);
        b.type = Reference(parameterElement.type.getName(),
            createElementPath(parameterElement.type.element!));
      }));

      final InjectedMembersVisitor visitor = InjectedMembersVisitor();
      memberElement.visitChildren(visitor);

      builder.body = Block((BlockBuilder b) {
        for (j.InjectedMember member in visitor.members.toSet()) {
          _log('build provide method for member: ${member.element}');
          final Tag? tag = member.element.getQualifierTag();
          b.addExpression(CodeExpression(Block.of(<Code>[
            Code('${parameterElement.name}.${member.element.name}'),
            Code(' = ${_generateAssignString(member.element.type, tag)}'),
          ])));
        }

        if (memberElement.getInjectedMethods().isNotEmpty) {
          b.addExpression(
            _callInjectedMethodsIfNeeded(
              CodeExpression(Code(parameterElement.name)),
              memberElement,
            ),
          );
        }
      });

      return builder.build();
    }).toList();
  }

  ///
  /// Return example: '_myRepositoryProvider.get()
  /// or _myRepositoryProvider if callGet passed as false
  ///
  String _generateAssignString(
    DartType type,
    Tag? tag, [
    bool callGet = true,
  ]) {
    type.checkUnsupportedType();

    if (type == _componentType) {
      return 'this';
    }

    if (type.isProvider) {
      final DartType depType = type.providerType;
      final ProviderSource? provider =
          _componentContext.findProvider(depType, tag);

      if (provider == null && depType.hasInjectedConstructor()) {
        return _generateAssignString(
          depType,
          null,
          false,
        );
      }
      check(
        provider != null,
        () => providerNotFound(depType, tag),
      );
      return _generateAssignString(
        provider!.type,
        provider.tag,
        false,
      );
    }

    final ProviderSource? provider = _componentContext.findProvider(type, tag);

    if (provider is BuildInstanceSource) {
      final String? finalSting;

      if (tag == null) {
        finalSting = null;
      } else {
        finalSting = generateMd5(tag.uniqueId);
      }

      return '_${_generateFieldName(type, finalSting)}';
    }

    if (provider is AnotherComponentSource) {
      return provider.assignString;
    }

    final InjectedConstructorsVisitor visitor = InjectedConstructorsVisitor();
    type.element!.visitChildren(visitor);

    if (visitor.injectedConstructors.isEmpty) {
      final j.Method? provideMethod =
          _componentContext.findProvideMethod(type: type, tag: tag);
      check(
        provideMethod != null,
        () => providerNotFound(type, tag),
      );
    }

    return _generateProviderCall(
      tag: tag,
      type: type,
      callGet: callGet,
    );
  }

  /// Returns a provider call as string, which can be used in the [Code].
  /// It is assumed that the provider exists as a field of the component.
  /// [tag] is used as class field prefix if exists.
  /// [callGet] is used to optionally call a .get() on a provider.
  String _generateProviderCall({
    required Tag? tag,
    required DartType type,
    required bool callGet,
  }) {
    final String? finalTag;

    if (tag == null) {
      finalTag = null;
    } else {
      finalTag = generateMd5(tag.uniqueId);
    }

    return '_${_generateFieldName(type, finalTag)}Provider${callGet ? '.get()' : ''}';
  }

  /// Generate field name of given type. Uses the tag if it exists. Usually
  /// generates a name for a class field.
  /// If the type has invalid characters, such as brackets, they will be
  /// stripped.
  String _generateFieldName(DartType type, String? tag) {
    final String typeName = type
        .getName()
        .replaceAll('<', '_')
        .replaceAll('>', '_')
        .replaceAll(' ', '')
        .replaceAll(',', '_');
    if (tag != null) {
      return 'named_${tag}_$typeName';
    }

    return '${uncapitalize(typeName)}';
  }

  Method _buildInitNonLazyMethod(ComponentContext _componentContext) {
    final MethodBuilder builder = MethodBuilder();
    builder.name = '_initNonLazy';
    builder.returns = const Reference('void');
    builder.body = Block((BlockBuilder builder) {
      final Iterable<ProviderSource> nonLazyProviders = _componentContext
          .providerSources
          .whereType<ModuleSource>()
          .where((ProviderSource source) => source.annotations.any(
              (j.Annotation annotation) => annotation is j.NonLazyAnnotation))
          .toList()
        ..sort((ProviderSource a, ProviderSource b) =>
            a.type.getName().compareTo(b.type.getName()));

      for (ProviderSource source in nonLazyProviders) {
        builder.statements.add(
          Code('${_generateAssignString(
            source.type,
            source.tag,
          )};'),
        );
      }
    });

    return builder.build();
  }

  bool hasNonLazyProviders() {
    return _componentContext.providerSources.any((ProviderSource source) =>
        source.annotations.any(
            (j.Annotation annotation) => annotation is j.NonLazyAnnotation));
  }

  // region provider

  /// example: SingletonProvider<MyProvider>(() => AppModule.provideMyProvider());
  // TODO(Ivan): pass DartType instead ClassElement
  Code _buildProviderFromClassAssignCode(ClassElement element) {
    _log(
      'build provider from class: ${element.toNameWithPath()}',
    );
    final InjectedConstructorsVisitor visitor = InjectedConstructorsVisitor();
    element.visitChildren(visitor);

    check(
      visitor.injectedConstructors.length == 1,
      () => injectedConstructorNotFound(element),
    );
    final ConstructorElement injectedConstructor =
        visitor.injectedConstructors[0];
    final List<ParameterElement> parameters = injectedConstructor.parameters;

    final Expression newInstance =
        _getProviderReferenceOfElement(injectedConstructor)
            .newInstance(<Expression>[
      _buildExpressionBodyExpression(
        _buildCallMethodOrConstructor(element, parameters, _componentContext),
      ),
    ]);

    return newInstance.code;
  }

  /// Build provider from given method.
  /// Example of Result:
  /// ```
  /// SingletonProvider<MyProvider>(() => AppModule.provideMyProvider());
  /// ```
  Code _buildProviderFromMethodCode(MethodElement method) {
    _log(
      'build provider from method: ${method.toNameWithPath()}',
    );
    if (method.isStatic) {
      return _buildProviderFromStaticMethodCode(
        method,
        _componentContext,
        _allocator,
      );
    } else if (method.isAbstract) {
      return _buildProviderFromAbstractMethodCode(method);
    } else {
      throw JuggerError(
        'provided method must be abstract or static [${method.enclosingElement.name}.${method.name}]',
      );
    }
  }

  /// Build provider from given method with given source. Use source for
  /// construct assign code of provider.
  Code _buildProvider(MethodElement method, ProviderSource source) {
    final Expression newInstance =
        _getProviderReferenceOfElement(method).newInstance(
      <Expression>[
        _buildExpressionBodyExpression(
          Code('${_generateAssignString(
            source.type,
            source.tag,
          )}'),
        ),
      ],
    );

    return newInstance.code;
  }

  /// Build provider from given method. Method must have only 'bind' type.
  Code _buildProviderFromAbstractMethodCode(MethodElement method) {
    _log(
        'build provider from abstract method: ${method.enclosingElement.toNameWithPath()}');

    check(
      method.parameters.length == 1,
      () =>
          'method annotates [${jugger.binds.runtimeType}] must have 1 parameter',
    );

    final Element rawParameter = method.parameters[0].type.element!;
    final ClassElement parameter;
    if (rawParameter is ClassElement) {
      parameter = rawParameter;
    } else {
      throw JuggerError('parameter must be class [${rawParameter.name}]');
    }

    final InjectedConstructorsVisitor visitor = InjectedConstructorsVisitor();
    parameter.visitChildren(visitor);

    final ProviderSource? provider =
        _componentContext.findProvider(parameter.thisType, null);

    final bool isSupertype = parameter.allSupertypes.any(
        (InterfaceType interfaceType) =>
            interfaceType.element.name ==
            method.returnType.getDisplayString(withNullability: false));

    check(
      isSupertype,
      () => bindWrongType(method),
    );
    if (provider is AnotherComponentSource) {
      return _buildProvider(method, provider);
    } else if (provider is ModuleSource) {
      return _buildProvider(method, provider);
    }

    check(
      visitor.injectedConstructors.length == 1,
      () => injectedConstructorNotFound(parameter),
    );
    final ConstructorElement injectedConstructor =
        visitor.injectedConstructors[0];
    final List<ParameterElement> parameters = injectedConstructor.parameters;

    if (getBindAnnotation(method) != null) {
      final Element? bindedElement = method.parameters[0].type.element;
      check(
        bindedElement is ClassElement,
        () => '$bindedElement not supported.',
      );
      final Expression newInstance = _getProviderReferenceOfElement(
        method,
      ).newInstance(
        <Expression>[
          _buildExpressionBodyExpression(
            Code(
              _generateAssignString(
                (bindedElement as ClassElement).thisType,
                null,
              ),
            ),
          ),
        ],
      );
      return newInstance.code;
    } else if (getProvideAnnotation(method) != null) {
      check(
        method.returnType.element is ClassElement,
        () => '${method.returnType.element} not supported.',
      );
    } else {
      throw JuggerError(
          'unknown provided type of method ${method.getDisplayString(withNullability: false)}');
    }

    final Expression newInstance =
        _getProviderReferenceOfElement(method).newInstance(<Expression>[
      _buildExpressionBodyExpression(
        _buildCallMethodOrConstructor(parameter, parameters, _componentContext),
      ),
    ]);

    return newInstance.code;
  }

  // endregion provider

  /// Build expression body with given body of code.
  /// Example result:
  /// ```
  /// () => print('hello')
  /// ```
  Expression _buildExpressionBodyExpression(Code body) {
    return CodeExpression(
      Block.of(
        <Code>[
          ...<Code>[
            const Code('() => '),
            body,
          ],
        ],
      ),
    );
  }

  Code _buildProviderFromStaticMethodCode(
    MethodElement method,
    ComponentContext _componentContext,
    Allocator allocator,
  ) {
    _log(
        'build provider from static method: ${method.enclosingElement.name}.${method.name}');

    check(
      method.returnType.element is ClassElement,
      () => '${method.returnType.element} not supported.',
    );
    final Element moduleClass = method.enclosingElement;
    final Expression newInstance =
        _getProviderReferenceOfElement(method).newInstance(<Expression>[
      _buildExpressionBodyExpression(
        Block.of(
          <Code>[
            refer(moduleClass.name!, createElementPath(moduleClass)).code,
            const Code('.'),
            _buildCallMethodOrConstructor(
              method,
              method.parameters,
              _componentContext,
            )
          ],
        ),
      )
    ]);

    return newInstance.code;
  }

  // TODO(Ivan): split to two methods
  Code _buildCallMethodOrConstructor(
    Element element,
    List<ParameterElement> parameters,
    ComponentContext _componentContext,
  ) {
    _log('build CallMethodOrConstructor for: ${element.name}');
    check(
      (element is ClassElement) || (element is MethodElement),
      () => 'element${element.name} must be ClassElement or MethodElement',
    );

    Reference r(String symbol) {
      if (element is MethodElement) {
        return refer(element.name);
      }
      return refer(element.name!, createElementPath(element));
    }

    /// handle case:
    ///   @singleton
    ///   @provide
    ///   static UpdatesProvider provideUpdatesProvider() => UpdatesProvider();
    ///
    ///   @singleton
    ///   @bind
    ///   IChatUpdatesProvider bindChatUpdatesProvider(UpdatesProvider impl);
    if (element is ClassElement) {
      final ProviderSource? provider =
          _componentContext.findProvider(element.thisType, null);

      if (provider is ModuleSource) {
        return Code('${_generateAssignString(
          provider.type,
          provider.tag,
        )}');
      }
    }

    if (parameters.isEmpty) {
      final Reference reference = r(element.name!);
      late final Expression instanceExpression;
      if (element is ClassElement &&
          element.constructors.first.isConst &&
          element.constructors.first.parameters.isEmpty) {
        instanceExpression = reference.constInstance(<Expression>[]);
      } else {
        instanceExpression = reference.newInstance(<Expression>[]);
      }
      return _callInjectedMethodsIfNeeded(instanceExpression, element).code;
    }

    final bool isPositional =
        parameters.any((ParameterElement p) => p.isPositional);
    final bool isNamed = parameters.any((ParameterElement p) => p.isNamed);

    check(
      !(isPositional && isNamed),
      () => 'all parameters must be Positional or Named [${element.name}]',
    );

    if (isPositional) {
      final Expression newInstanceExpression = r(element.name!).newInstance(
        _buildArgumentsExpression(element, parameters, _componentContext)
            .values
            .toList(),
      );
      return _callInjectedMethodsIfNeeded(newInstanceExpression, element).code;
    }

    if (isNamed) {
      final Expression newInstance = r(element.name!).newInstance(
        <Expression>[],
        _buildArgumentsExpression(element, parameters, _componentContext),
      );
      return _callInjectedMethodsIfNeeded(newInstance, element).code;
    }

    throw JuggerError('unexpected state');
  }

  Expression _callInjectedMethodsIfNeeded(
    Expression initialExpression,
    Element element,
  ) {
    if (element is ClassElement) {
      final Set<MethodElement> methods = element.getInjectedMethods();
      if (methods.isNotEmpty) {
        final List<Code> methodsCalls = methods.expand((MethodElement method) {
          final Code methodCall = _buildCallMethodOrConstructor(
              method, method.parameters, _componentContext);
          return <Code>[
            const Code('..'),
            methodCall,
          ];
        }).toList();
        return CodeExpression(Block.of(
          <Code>[
            initialExpression.code,
            ...methodsCalls,
          ],
        ));
      }
    }

    return initialExpression;
  }

  /// Returns a provider reference that returns the type that is associated with
  /// the element.
  /// Only certain element types are supported, otherwise throws an error.
  Reference _getProviderReferenceOfElement(Element element) {
    check(
      element is MethodElement || element is ConstructorElement,
      () => '$element not supported',
    );

    // type inside brackets
    final String generic = _getClassTypeAsString(element);

    if (element is ConstructorElement) {
      return _getProviderReference(
        generic: generic,
        singleton: element.enclosingElement.hasAnnotatedAsSingleton(),
      );
    }

    return _getProviderReference(
      generic: generic,
      singleton: element.hasAnnotatedAsSingleton(),
    );
  }

  /// Returns a provider reference based on the passed parameters.
  /// [generic] it is type which will be enclosed in brackets '<>'. Must be
  /// allocated by Allocator, otherwise there will be syntax errors.
  ///
  /// [singleton] true if provider type is singleton.
  Reference _getProviderReference({
    required String generic,
    required bool singleton,
  }) {
    return refer(
        singleton ? 'SingletonProvider<$generic>' : 'Provider<$generic>',
        'package:jugger/jugger.dart');
  }

  /// Returns the string class type of the given element and allocates it.
  /// Only certain element types are supported, otherwise throws an error.
  String _getClassTypeAsString(Element element) {
    if (element is ConstructorElement) {
      final ClassElement c = element.enclosingElement;
      return _allocator.allocate(
          Reference(c.thisType.getName(), c.librarySource.uri.toString()));
    } else if (element is MethodElement) {
      return _allocator.allocate(refer(_allocateTypeName(element.returnType)));
    }
    throw JuggerError(
        'unsupported type: ${element.name}, ${element.runtimeType}');
  }

  /// Build constructor for this component. If the component has a builder, it
  /// will be private, because depending on whether it has one or not, the
  /// creation of the component is different.
  Constructor _buildConstructor(j.ComponentBuilder? componentBuilder) {
    return Constructor((ConstructorBuilder constructorBuilder) {
      // constructorBuilder.body = const Code('_init();');
      if (hasNonLazyProviders()) {
        constructorBuilder.body = const Code('_initNonLazy();');
      }

      if (componentBuilder == null) {
        constructorBuilder.name = 'create';
      } else {
        constructorBuilder.name = '_create';
        constructorBuilder.requiredParameters.addAll(componentBuilder.parameters
            .map((j.ComponentBuilderParameter parameter) {
          return Parameter((ParameterBuilder b) {
            b.toThis = true;
            final Tag? tag =
                parameter.parameter.enclosingElement!.getQualifierTag();
            b.name = '_${_generateFieldName(
              parameter.parameter.type,
              tag?._toAssignTag(),
            )}';
          });
        }));
      }
    });
  }

  List<Field> _buildConstructorFields(j.ComponentBuilder? componentBuilder) {
    if (componentBuilder == null) {
      return <Field>[];
    }

    return componentBuilder.parameters
        .map((j.ComponentBuilderParameter parameter) {
      // ignore: unnecessary_parenthesis
      return (Field((FieldBuilder b) {
        final Tag? tag =
            parameter.parameter.enclosingElement!.getQualifierTag();
        b.name = '_${_generateFieldName(
          parameter.parameter.type,
          tag?._toAssignTag(),
        )}';
        b.modifier = FieldModifier.final$;
        b.type = refer(_allocateTypeName(parameter.parameter.type));
      }));
    }).toList();
  }

  Map<String, Expression> _buildArgumentsExpression(
    Element forElement,
    List<ParameterElement> parameters,
    ComponentContext _componentContext,
  ) {
    _log('build arguments for ${forElement.name}: $parameters');

    if (parameters.isEmpty) {
      return HashMap<String, Expression>();
    }

    final Iterable<MapEntry<String, Expression>> map =
        parameters.map((ParameterElement parameter) {
      final CodeExpression codeExpression = CodeExpression(
        Block.of(<Code>[
          Code(
            _generateAssignString(
              parameter.type,
              getQualifierAnnotation(parameter)?.tag,
            ),
          ),
        ]),
      );
      return MapEntry<String, Expression>(parameter.name, codeExpression);
    });
    return Map<String, Expression>.fromEntries(map);
  }

  void _log(String value) => _logs.add(value);
}

extension _StringExt on Tag {
  String _toAssignTag() => generateMd5(uniqueId);
}

extension ElementExt on Element {
  DartType _tryGetType() {
    final Element element = this;
    if (element is ClassElement) {
      return element.thisType;
    } else if (element is ParameterElement) {
      return element.type;
    }

    throw JuggerError('unable get type of [$element]');
  }
}
