import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:jugger/jugger.dart' as jugger;
import 'package:jugger_generator/src/dart_type_ext.dart';
import 'package:jugger_generator/src/utils.dart';

import 'check_unused_providers.dart';
import 'classes.dart' as j;
import 'component_context.dart';
import 'global_config.dart';
import 'jugger_error.dart';
import 'messages.dart';
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

        // final List<j.ModuleAnnotation> modules = component.modules;

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

          // classBuilder.methods.add(_buildInitMethod());

          // classBuilder.methods.add(
          //   _buildInitProvidesMethod(
          //     _componentContext.dependencies,
          //     modules,
          //     _componentContext,
          //     _allocator,
          //   ),
          // );

          if (hasNonLazyProviders()) {
            classBuilder.methods
                .add(_buildInitNonLazyMethod(_componentContext));
          }

          classBuilder.methods.addAll(_buildMembersInjectorMethods(
              component.methods, classBuilder, _componentContext));

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
                parameterBuilder.type = Reference(
                    pe.type.getName(), createElementPath(pe.type.element!));
              });
            }));

            b.body = Block((BlockBuilder b) {
              if (m.name == 'build') {
                final Iterable<Expression> map = componentBuilder.parameters
                    .map((j.ComponentBuilderParameter parameter) {
                  final String? tag =
                      parameter.parameter.enclosingElement!.getQualifierTag();
                  final Element? classElement =
                      parameter.parameter.type.element;

                  check(
                    classElement is ClassElement,
                    'element[$classElement] is not ClassElement',
                  );

                  final CodeExpression codeExpression =
                      CodeExpression(Block.of(<Code>[
                    Code('_${_generateName(
                      (classElement as ClassElement).thisType,
                      tag?._toAssignTag(),
                    )}!'),
                  ]));
                  return codeExpression;
                });

                final List<Code> assertCodes = componentBuilder.parameters
                    .map((j.ComponentBuilderParameter parameter) {
                  final String? tag =
                      parameter.parameter.enclosingElement!.getQualifierTag();
                  return Code('assert(_${_generateName(
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
                final String? tag =
                    p.parameter.enclosingElement!.getQualifierTag();
                b.addExpression(CodeExpression(Block.of(<Code>[
                  Code('_${_generateName(
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
            b.type = Reference('${parameter.parameter.type.getName()}?',
                createElementPath(parameter.parameter.type.element!));
            final String? tag =
                parameter.parameter.enclosingElement!.getQualifierTag();
            b.name = '_${_generateName(
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

    for (Dependency dependency in _filterDependenciesForFields(dependencies)) {
      _log(
        'process: ${dependency.enclosingElement.toNameWithPath()}',
      );

      final bool isProvider = dependency.type.isProvider;

      if (isProvider) {
        continue;
      }

      final ProviderSource? provider =
          _componentContext.findProvider(dependency.type, dependency.named);

      if (!(provider is BuildInstanceSource) &&
          !(provider is AnotherComponentSource)) {
        fields.add(Field((FieldBuilder b) {
          final String? tag = dependency.enclosingElement.getQualifierTag();
          b.name = '_${_generateName(
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
            b.assignment = _buildProviderFromModuleAssignCode(
              provider.method.element,
            );
          } else {
            final ClassElement typeElement =
                dependency.type.element as ClassElement;

            check(
              !(isCore(typeElement) || typeElement.isAbstract),
              '${dependency.enclosingElement.name}.${dependency.type.getName()} (qualifier: $tag) not provided',
            );
            // if (_isBindDependency(dependency)) {
            //   continue;
            // }
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
    final Element enclosingElement = dependency.enclosingElement;
    if (enclosingElement is MethodElement) {
      return _allocateTypeName(enclosingElement.returnType);
    }

    return _allocateTypeName(dependency.type);
  }

  String _allocateTypeName(DartType t) {
    check(t is InterfaceType, 'type [$t] not supported');
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

  bool _isBindDependency(Dependency dependency) {
    if (dependency.enclosingElement is ParameterElement) {
      if (dependency.enclosingElement.enclosingElement is MethodElement) {
        return getBindAnnotation(
                dependency.enclosingElement.enclosingElement!) !=
            null;
      }
    }
    return false;
  }

  List<Method> _buildProvideProperties(ComponentContext _componentContext) {
    final List<PropertyAccessorElement> properties =
        _componentContext.component.provideProperties;

    return properties.map((PropertyAccessorElement property) {
      _log(
          'build property for: ${property.enclosingElement.name}.${property.name}');
      return Method((MethodBuilder builder) {
        final String? tag = property.getQualifierTag();
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
        _componentContext.component.provideMethod;
    final List<Method> newProperties = <Method>[];

    for (MethodElement method in methods) {
      _log(
          'build provide method for: ${method.enclosingElement.name}.${method.name}');
      final Method m = Method((MethodBuilder b) {
        b.annotations.add(_overrideAnnotationExpression);
        b.name = method.name;
        b.returns = refer(_allocateTypeName(method.returnType));

        final String? tag = method.getQualifierTag();
        final ProviderSource? providerSource =
            _componentContext.findProvider(method.returnType, tag);

        check(providerSource != null,
            '[${method.returnType.element!.name}, qualifier: $tag] not provided');

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

  /*
  Method _buildInitMethod() {
    return Method((MethodBuilder b) {
      b.name = '_init';
      b.body = Block((BlockBuilder builder) {
        builder.statements.add(const Code('_initProvides();'));
        if (hasNonLazyProviders()) {
          builder.statements.add(const Code('_initNonLazy();'));
        }
      });
      b.returns = const Reference('void');
    });
  }
  */

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
      check(method.element.parameters.length == 1,
          'method ${method.element.name} must have 1 parameter');

      final ParameterElement parameterElement = method.element.parameters[0];

      builder.requiredParameters.add(Parameter((ParameterBuilder b) {
        b.name = uncapitalize(parameterElement.name);
        b.type = Reference(parameterElement.type.getName(),
            createElementPath(parameterElement.type.element!));
      }));

      final InjectedMembersVisitor visitor = InjectedMembersVisitor();
      parameterElement.type.element!.visitChildren(visitor);

      builder.body = Block((BlockBuilder b) {
        for (j.InjectedMember member in visitor.members.toSet()) {
          _log('build provide method for member: ${member.element}');
          final String? tag = member.element.getQualifierTag();
          b.addExpression(CodeExpression(Block.of(<Code>[
            Code('${parameterElement.name}.${member.element.name}'),
            Code(' = ${_generateAssignString(member.element.type, tag)}'),
          ])));
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
    String? name, [
    bool callGet = true,
  ]) {
    if (type == _componentType) {
      return 'this';
    }

    if (type.isProvider) {
      final InterfaceType interfaceType = type as InterfaceType;
      assert(interfaceType.typeArguments.length == 1);

      final DartType depType = interfaceType.typeArguments.first;
      final ProviderSource? provider =
          _componentContext.findProvider(depType, name);
      check2(
        provider != null,
        () => providerNotFound(depType, name),
      );
      return _generateAssignString(
        provider!.type,
        provider.tag,
        false,
      );
    }

    // if (!(element is ClassElement)) {
    //   throw JuggerError('element[$element] is not ClassElement');
    // }

    final ProviderSource? provider = _componentContext.findProvider(type, name);

    if (provider is BuildInstanceSource) {
      return provider.assignString;
    }

    if (provider is AnotherComponentSource) {
      return provider.assignString;
    }

    final InjectedConstructorsVisitor visitor = InjectedConstructorsVisitor();
    type.element!.visitChildren(visitor);

    if (visitor.injectedConstructors.isEmpty) {
      final j.Method? provideMethod =
          _componentContext.findProvideMethod(type, name);
      check2(
        provideMethod != null,
        () => providerNotFound(type, name),
      );
    }

    final String? finalSting;

    if (name == null) {
      finalSting = null;
    } else {
      finalSting = generateMd5(name);
    }

    return '_${_generateName(type, finalSting)}Provider${callGet ? '.get()' : ''}';
  }

  String _generateName(DartType type, String? name) {
    final String typeName = type
        .getName()
        .replaceAll('<', '_')
        .replaceAll('>', '_')
        .replaceAll(' ', '')
        .replaceAll(',', '_');
    if (name != null) {
      return 'named_${name}_$typeName';
    }

    return '${uncapitalize(typeName)}';
  }

  /*
  Method _buildInitProvidesMethod(
    List<Dependency> dependencies,
    List<j.ModuleAnnotation> modules,
    ComponentContext _componentContext,
    Allocator allocator,
  ) {
    final MethodBuilder builder = MethodBuilder();
    builder.name = '_initProvides';
    builder.returns = const Reference('void');

    // ignore: unnecessary_parenthesis
    builder.body = Block(((BlockBuilder b) {
      for (Dependency dependency in dependencies) {
        _log(
            'build provider for dependency: ${dependency.enclosingElement.name}.${dependency.element.name}');
        final String? tag =
            getQualifierAnnotation(dependency.enclosingElement)?.tag;
        final ProviderSource? provider =
            _componentContext.findProvider(dependency.element, tag);

        if (provider is ModuleSource) {
          b.addExpression(
            _buildProviderFromModuleAssignExpression(
              provider.method.element,
            ),
          );
        } else if (provider is BuildInstanceSource) {
          print('${provider.providedClass} is BuildInstanceSource');
        } else if (provider is AnotherComponentSource) {
          print('${provider.providedClass} is AnotherComponentSource');
        } else {
          if (isCore(dependency.element) || dependency.element.isAbstract) {
            throw JuggerError(
              '${dependency.enclosingElement.name}.${dependency.element.name} (qualifier: $tag) not provided',
            );
          }
          if (_isBindDependency(dependency)) {
            continue;
          }
          b.addExpression(
            _buildProviderFromClassAssignExpression(dependency.element),
          );
        }
      }
    }));
    return builder.build();
  }
  */

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

  /*
  /// example: _myProvider = SingletonProvider<MyProvider>(() => AppModule.provideMyProvider());
  Expression _buildProviderFromClassAssignExpression(ClassElement element) {
    _log('build provider from class: ${element.name}');
    return CodeExpression(
      Block.of(
        <Code>[
          Code('_${uncapitalize(element.name)}Provider = '),
          _buildProviderFromClassAssignCode(element),
        ],
      ),
    );
  }
  */

  /// example: SingletonProvider<MyProvider>(() => AppModule.provideMyProvider());
  // TODO(Ivan): pass DartType instead ClassElement
  Code _buildProviderFromClassAssignCode(ClassElement element) {
    _log(
      'build provider from class: ${element.toNameWithPath()}',
    );
    final InjectedConstructorsVisitor visitor = InjectedConstructorsVisitor();
    element.visitChildren(visitor);

    check2(
      visitor.injectedConstructors.length == 1,
      () => injectedConstructorNotFound(element),
    );
    final j.InjectedConstructor injectedConstructor =
        visitor.injectedConstructors[0];
    final List<ParameterElement> parameters =
        injectedConstructor.element.parameters;

    final Expression newInstance =
        getProviderType(injectedConstructor.element).newInstance(<Expression>[
      CodeExpression(Block.of(_buildProviderBody(element, <Code>[
        _buildCallMethodOrConstructor(element, parameters, _componentContext)
      ])))
    ]);

    return newInstance.code;
  }

  /*
  /// example: _myProvider = SingletonProvider<MyProvider>(() => AppModule.provideMyProvider());
  Expression _buildProviderFromModuleAssignExpression(MethodElement method) {
    _log(
        'build provider from module: ${method.enclosingElement.name}.${method.name}');

    final String? tag = getQualifierAnnotation(method)?.tag;

    return CodeExpression(
      Block.of(
        <Code>[
          Code('_${_generateName(method.returnType.element!, tag)}Provider = '),
          _buildProviderFromModuleAssignCode(method),
        ],
      ),
    );
  }
  */

  /// example: SingletonProvider<MyProvider>(() => AppModule.provideMyProvider());
  Code _buildProviderFromModuleAssignCode(MethodElement method) {
    _log(
      'build provider from module: ${method.toNameWithPath()}',
    );
    Expression expression;
    if (method.isStatic) {
      expression = _buildProviderFromStaticMethod(
        method,
        _componentContext,
        _allocator,
      );
    } else if (method.isAbstract) {
      expression = _buildProviderFromAbstractMethod(method);
    } else {
      throw JuggerError(
        'provided method must be abstract or static [${method.enclosingElement.name}.${method.name}]',
      );
    }
    return expression.code;
  }

  ///
  /// [method]: provider method
  ///
  /// example:
  /// ```dart main
  /// @singleton
  /// @bind
  /// IFoldersScreenRouter bindFoldersScreenRouter(IFoldersRouter router);
  /// ```
  ///
  // todo refactor as AssignCode, must return Code
  Expression _buildProviderFromAnotherComponent(
    MethodElement method,
    AnotherComponentSource provider,
  ) {
    final Expression newInstance = getProviderType(method).newInstance(
      <Expression>[
        CodeExpression(
          Block.of(
            _buildProviderBody(
              provider.dependencyClass,
              <Code>[
                Code(provider.assignString),
              ],
            ),
          ),
        ),
      ],
    );

    return CodeExpression(newInstance.code);
  }

  // todo refactor as AssignCode, must return Code
  Expression _buildProviderFromModule(
    MethodElement method,
    ModuleSource provider,
  ) {
    final Expression newInstance = getProviderType(method).newInstance(
      <Expression>[
        CodeExpression(
          Block.of(
            _buildProviderBody(
              provider.moduleClass,
              <Code>[
                Code('${_generateAssignString(
                  provider.type,
                  provider.tag,
                )}'),
              ],
            ),
          ),
        ),
      ],
    );

    return CodeExpression(newInstance.code);
  }

  // todo refactor as AssignCode, must return Code
  Expression _buildProviderFromAbstractMethod(MethodElement method) {
    _log(
        'build provider from abstract method: ${method.enclosingElement.toNameWithPath()}');

    check(method.parameters.length == 1,
        'method annotates [${jugger.binds.runtimeType}] must have 1 parameter');

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

    check2(
      isSupertype,
      () => bindWrongType(method),
    );
    if (provider is AnotherComponentSource) {
      return _buildProviderFromAnotherComponent(method, provider);
    } else if (provider is ModuleSource) {
      return _buildProviderFromModule(method, provider);
    }

    check2(
      visitor.injectedConstructors.length == 1,
      () => injectedConstructorNotFound(parameter),
    );
    final j.InjectedConstructor injectedConstructor =
        visitor.injectedConstructors[0];
    final List<ParameterElement> parameters =
        injectedConstructor.element.parameters;

    final ClassElement returnClass;
    if (getBindAnnotation(method) != null) {
      final Element? bindedElement = method.parameters[0].type.element;
      check(
        bindedElement is ClassElement,
        '$bindedElement not supported.',
      );
      // ignore: avoid_as
      returnClass = bindedElement as ClassElement;
      final Expression newInstance = getProviderType(
        method,
      ).newInstance(
        <Expression>[
          CodeExpression(
            Block.of(
              _buildProviderBody(
                returnClass,
                <Code>[
                  Code(_generateAssignString(bindedElement.thisType, null)),
                ],
              ),
            ),
          )
        ],
      );
      return CodeExpression(newInstance.code);
    } else if (getProvideAnnotation(method) != null) {
      check(
        method.returnType.element is ClassElement,
        '${method.returnType.element} not supported.',
      );
      // ignore: avoid_as
      returnClass = method.returnType.element as ClassElement;
    } else {
      throw JuggerError(
          'unknown provided type of method ${method.getDisplayString(withNullability: false)}');
    }

    final Expression newInstance =
        getProviderType(method).newInstance(<Expression>[
      CodeExpression(
        Block.of(
          _buildProviderBody(
            returnClass,
            <Code>[
              _buildCallMethodOrConstructor(
                  parameter, parameters, _componentContext)
            ],
          ),
        ),
      )
    ]);

    return CodeExpression(newInstance.code);
  }

  List<Code> _buildProviderBody(ClassElement classElement, List<Code> code) {
    final List<Code> codes = <Code>[];

    final Code primaryExpression = CodeExpression(Block.of(code)).code;
    codes.addAll(<Code>[
      const Code('() => '),
      primaryExpression,
    ]);
    return codes;
  }

  // todo refactor as AssignCode, must return Code
  Expression _buildProviderFromStaticMethod(
    MethodElement method,
    ComponentContext _componentContext,
    Allocator allocator,
  ) {
    _log(
        'build provider from static method: ${method.enclosingElement.name}.${method.name}');

    check(
      method.returnType.element is ClassElement,
      '${method.returnType.element} not supported.',
    );
    // ignore: avoid_as
    final ClassElement returnClass = method.returnType.element as ClassElement;
    final Element moduleClass = method.enclosingElement;
    final Expression newInstance =
        getProviderType(method).newInstance(<Expression>[
      CodeExpression(Block.of(_buildProviderBody(returnClass, <Code>[
        refer(moduleClass.name!, createElementPath(moduleClass)).code,
        const Code('.'),
        _buildCallMethodOrConstructor(
            method, method.parameters, _componentContext)
      ])))
    ]);

    return CodeExpression(newInstance.code);
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
      'element${element.name} must be ClassElement or MethodElement',
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
      late final Expression instance;
      if (element is ClassElement &&
          element.constructors.first.isConst &&
          element.constructors.first.parameters.isEmpty) {
        instance = reference.constInstance(<Expression>[]);
      } else {
        instance = reference.newInstance(<Expression>[]);
      }
      return instance.code;
    }

    final bool isPositional =
        parameters.any((ParameterElement p) => p.isPositional);
    final bool isNamed = parameters.any((ParameterElement p) => p.isNamed);

    check(
      !(isPositional && isNamed),
      'all parameters must be Positional or Named [${element.name}]',
    );

    if (isPositional) {
      return r(element.name!)
          .newInstance(
            _buildArgumentsExpression(element, parameters, _componentContext)
                .values
                .toList(),
          )
          .code;
    }

    if (isNamed) {
      return r(element.name!).newInstance(
        <Expression>[],
        _buildArgumentsExpression(element, parameters, _componentContext),
      ).code;
    }

    throw JuggerError('unexpected state');
  }

  Reference getProviderType(Element element) {
    check(
      element is MethodElement || element is ConstructorElement,
      '$element not supported',
    );

    final String generic = _getGeneric(element);

    if (element is ConstructorElement) {
      return getProviderReference(
        generic: generic,
        singleton: element.enclosingElement.hasAnnotatedAsSingleton(),
      );
    }

    return getProviderReference(
      generic: generic,
      singleton: element.hasAnnotatedAsSingleton(),
    );
  }

  Reference getProviderReference(
      {required String generic, required bool singleton}) {
    return refer(
        singleton ? 'SingletonProvider<$generic>' : 'Provider<$generic>',
        'package:jugger/jugger.dart');
  }

  String _getGeneric(Element element) {
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
            final String? tag =
                parameter.parameter.enclosingElement!.getQualifierTag();
            b.name = '_${_generateName(
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
        final String? tag =
            parameter.parameter.enclosingElement!.getQualifierTag();
        b.name = '_${_generateName(
          parameter.parameter.type,
          tag?._toAssignTag(),
        )}';
        b.modifier = FieldModifier.final$;
        b.type = Reference(parameter.parameter.type.getName(),
            createElementPath(parameter.parameter.type.element!));
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

extension _StringExt on String {
  String _toAssignTag() => generateMd5(this);
}
