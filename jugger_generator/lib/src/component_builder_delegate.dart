// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:jugger_generator/src/utils.dart';

import 'classes.dart' as j;
import 'component_context.dart';
import 'visitors.dart';

class ComponentBuilderDelegate {
  late ComponentContext _componentContext;
  late Allocator _allocator;
  final List<String> _logs = <String>[];

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

        final List<j.ModuleAnnotation> modules = component.modules;

        target.body.add(Class((ClassBuilder classBuilder) {
          classBuilder.fields.addAll(
            _buildProvidesFields(
              _componentContext.dependencies,
              _componentContext,
              _allocator,
            ),
          );
          classBuilder.fields.addAll(_buildConstructorFields(componentBuilder));
          _log(
              'build for component: ${component.element} [${component.element.library.identifier}]');
          classBuilder.methods.addAll(_buildProvideMethods(_componentContext));

          classBuilder.methods.add(_buildInitMethod());

          classBuilder.methods.add(
            _buildInitProvidesMethod(
              _componentContext.dependencies,
              modules,
              _componentContext,
              _allocator,
            ),
          );

          if (hasNonLazyProviders()) {
            classBuilder.methods
                .add(_buildInitNonLazyMethod(_componentContext));
          }

          classBuilder.methods.addAll(_buildMembersInjectorMethods(
              component.methods, classBuilder, _componentContext));

          classBuilder.implements
              .add(Reference(component.element.name, createElementPath(lib)));
/*
          if (_isMustDisposedCurrentComponent()) {
            classBuilder.mixins.add(const Reference(
                'DisposableBagMixin', 'package:jugger/jugger.dart'));
          } else {
            classBuilder.methods.add(Method((MethodBuilder b) {
              b.annotations.add(const CodeExpression(Code('override')));
              b.name = 'dispose';
              b.returns = const Reference('void');
              b.body = const Code('');
            }));
          }
*/

          classBuilder.constructors.add(_buildConstructor(componentBuilder));

          classBuilder..name = 'Jugger${component.element.name}';
        }));
      }

      final String string =
          target.build().accept(DartEmitter(allocator: _allocator)).toString();

      final String finalString = string.isEmpty
          ? ''
          : '// ignore_for_file: implementation_imports \n'
              '// ignore_for_file: prefer_const_constructors \n'
              '// ignore_for_file: always_specify_types \n'
              '// ignore_for_file: directives_ordering \n'
              ' $string';

      return DartFormatter().format(finalString);
    }

    return '';
  }

/*
  bool _isMustDisposedCurrentComponent() =>
      _componentContext.dependencies.any((Dependency dependency) {
        final ProviderSource? provider =
            _componentContext.findProvider(dependency.element);

        if ((provider != null && provider is ModuleSource ||
                provider is BuildInstanceSource) ||
            provider == null) {
          return _isDisposable(dependency.element);
        }
        return false;
      });
*/

  bool _isDisposable(ClassElement element) {
    return element.interfaces.any((InterfaceType element) =>
        element.getDisplayString(withNullability: false) == 'IDisposable');
  }

  void _generateComponentBuilders(LibraryBuilder target, LibraryElement lib,
      List<j.ComponentBuilder> componentBuilders) {
    for (int i = 0; i < componentBuilders.length; i++) {
      final j.ComponentBuilder componentBuilder = componentBuilders[i];

      target.body.add(Class((ClassBuilder classBuilder) {
        classBuilder.name =
            'Jugger${componentBuilder.componentClass.name}Builder';

        classBuilder.implements.add(
            Reference(componentBuilder.element.name, createElementPath(lib)));
        classBuilder.methods
            .addAll(componentBuilder.methods.map((MethodElement m) {
          return Method((MethodBuilder b) {
            b.annotations.add(const CodeExpression(Code('override')));
            b.name = m.name;
            b.returns = Reference(
                m.returnType.name, createElementPath(m.returnType.element!));
            b.requiredParameters.addAll(m.parameters.map((ParameterElement pe) {
              return Parameter((ParameterBuilder parameterBuilder) {
                parameterBuilder.name = pe.name;
                parameterBuilder.type = Reference(
                    pe.type.name, createElementPath(pe.type.element!));
              });
            }));

            b.body = Block((BlockBuilder b) {
              if (m.name == 'build') {
                final Iterable<Expression> map = componentBuilder.parameters
                    .map((j.ComponentBuilderParameter parameter) {
                  final String? name =
                      getNamedAnnotation(parameter.parameter.enclosingElement!)
                          ?.name;
                  final Element? classElement =
                      parameter.parameter.type.element;
                  if (!(classElement is ClassElement)) {
                    throw StateError(
                        'element[$classElement] is not ClassElement');
                  }

                  final CodeExpression codeExpression =
                      CodeExpression(Block.of(<Code>[
                    Code('_${_generateName(
                      classElement,
                      name,
                    )}!'),
                  ]));
                  return codeExpression;
                });

                final List<Code> assertCodes = componentBuilder.parameters
                    .map((j.ComponentBuilderParameter parameter) {
                  final String? name =
                      getNamedAnnotation(parameter.parameter.enclosingElement!)
                          ?.name;
                  return Code(
                      'assert(_${_generateName(parameter.parameter.type.element!, name)} != null) ');
                }).toList();

                for (Code value in assertCodes) {
                  b.addExpression(CodeExpression(value));
                }

                final Expression newInstance =
                    refer('Jugger${m.returnType.name}._create')
                        .newInstance(map);

                b.addExpression(CodeExpression(Block.of(<Code>[
                  const Code('return '),
                  ToCodeExpression(newInstance),
                ])));
              } else {
                final j.ComponentBuilderParameter p =
                    j.ComponentBuilderParameter(parameter: m.parameters[0]);
                final String? name =
                    getNamedAnnotation(p.parameter.enclosingElement!)?.name;
                b.addExpression(CodeExpression(Block.of(<Code>[
                  Code(
                      '_${_generateName(p.parameter.type.element!, name)} = ${p.parameter.name}; return this'),
                ])));
              }
            });
          });
        }));
        classBuilder.fields.addAll(componentBuilder.parameters
            .map((j.ComponentBuilderParameter parameter) {
          return Field((FieldBuilder b) {
            b.type = Reference('${parameter.parameter.type.name}?',
                createElementPath(parameter.parameter.type.element!));
            final String? name =
                getNamedAnnotation(parameter.parameter.enclosingElement!)?.name;
            b.name =
                '_${_generateName(parameter.parameter.type.element!, name)}';
          });
        }));
      }));
    }
  }

  List<Field> _buildProvidesFields(
    List<Dependency> dependencies,
    ComponentContext _componentContext,
    Allocator allocator,
  ) {
    final List<Field> fields = <Field>[];

    for (Dependency dependency in dependencies) {
      final ProviderSource? provider =
          _componentContext.findProvider(dependency.element, dependency.named);

      if (_isBindDependency(dependency)) {
        continue;
      }

      if (!(provider is BuildInstanceSource) &&
          !(provider is AnotherComponentSource)) {
        fields.add(Field((FieldBuilder b) {
          final String? name =
              getNamedAnnotation(dependency.enclosingElement)?.name;
          b.name = '_${_generateName(dependency.element, name)}Provider';

          final String generic = allocator.allocate(Reference(
              _getNameFromDependency(allocator, dependency),
              dependency.element.thisType.element.librarySource.uri
                  .toString()));
          // TODO(Ivan): temporary
          b.docs.add('late');
          b.type =
              Reference('IProvider<$generic>', 'package:jugger/jugger.dart');
        }));
      } else {
        print('skip generation provide field for $provider');
      }
    }

    return fields..sort((Field a, Field b) => a.name.compareTo(b.name));
  }

  /// example:
  /// ResultDispatcher
  String _getNameFromDependency(Allocator allocator, Dependency dependency) {
    final Element enclosingElement = dependency.enclosingElement;
    if (enclosingElement is MethodElement) {
      return _getNameFromMethod(enclosingElement, allocator);
    }

    return dependency.element.thisType.name!;
  }

  /// example:
  /// ResultDispatcher<_i1.UserCredentials>
  /// ResultDispatcher
  String _getNameFromMethod(MethodElement element, Allocator allocator) {
    final DartType returnType = element.returnType;

    if (returnType is InterfaceType) {
      return _getNameFromInterface(element, returnType, allocator);
    }

    return element.returnType.element!.name!;
  }

  String _getNameFromInterface(
      Element el, InterfaceType type, Allocator allocator) {
    final List<DartType> arguments = type.typeArguments;
    if (arguments.isNotEmpty) {
      return '${type.name!}${_getNameFromTypeArguments(arguments, allocator)}';
    }

    return type.element.name;
  }

  /// example:
  /// Map<int, List<String>>
  String _getNameFromTypeArguments(
      List<DartType> arguments, Allocator allocator) {
    final String join = '<${arguments.map((DartType e) {
      final Element? element2 = e.element;
      final ClassElement classElement = element2 is ClassElement
          ? element2
          : throw StateError('element is not ClassElement');

      String name;
      if (e is InterfaceType) {
        name = _getNameFromInterface(classElement, e, allocator);
      } else {
        name = classElement.name;
      }

      return allocator.allocate(Reference(
          name, classElement.thisType.element.librarySource.uri.toString()));
    }).join(',')}>';
    return join;
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

  List<Method> _buildProvideMethods(ComponentContext _componentContext) {
    final List<MethodElement> methods =
        _componentContext.component.provideMethod;
    final List<Method> newProperties = <Method>[];

    for (MethodElement method in methods) {
      _log(
          'build provide method for: ${method.enclosingElement.name}.${method.name}');
      final Method m = Method((MethodBuilder b) {
        b.annotations.add(const CodeExpression(Code('override')));
        b.name = method.name;
        b.returns = Reference(method.returnType.name,
            createElementPath(method.returnType.element!));

        final String? name = getNamedAnnotation(method)?.name;
        final ProviderSource? providerSource =
            _componentContext.findProvider(method.returnType.element!, name);

        check(providerSource != null,
            '${method.returnType.element!.name} not provided');

        b.body = Code(
            'return ${_generateAssignString(method.returnType.element!)};');
      });
      newProperties.add(m);
    }

    return newProperties
      ..sort((Method a, Method b) => a.name!.compareTo(b.name!));
  }

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

  List<Method> _buildMembersInjectorMethods(
    List<j.MemberInjectorMethod> fields,
    ClassBuilder classBuilder,
    ComponentContext _componentContext,
  ) {
    return fields.map((j.MemberInjectorMethod method) {
      final MethodBuilder builder = MethodBuilder();
      builder.name = method.element.name;
      builder.annotations.add(const CodeExpression(Code('override')));
      builder.returns = const Reference('void');
      check(method.element.parameters.length == 1,
          'method ${method.element.name} must have 1 parameter');

      final ParameterElement parameterElement = method.element.parameters[0];

      builder.requiredParameters.add(Parameter((ParameterBuilder b) {
        b.name = uncapitalize(parameterElement.name);
        b.type = Reference(parameterElement.type.name,
            createElementPath(parameterElement.type.element!));
      }));

      final InjectedMembersVisitor visitor = InjectedMembersVisitor();
      parameterElement.type.element!.visitChildren(visitor);

      builder.body = Block((BlockBuilder b) {
        for (j.InjectedMember member in visitor.members.toSet()) {
          _log('build provide method for member: ${member.element}');
          final String? name = getNamedAnnotation(member.element)?.name;
          b.addExpression(CodeExpression(Block.of(<Code>[
            Code('${parameterElement.name}.${member.element.name}'),
            Code(
                ' = ${_generateAssignString(member.element.type.element!, name)}'),
          ])));
        }
      });

      return builder.build();
    }).toList();
  }

  ///
  /// [element] element of provider
  /// Return example: '_myRepositoryProvider.get()
  ///
  String _generateAssignString(Element element, [String? name]) {
    if (!(element is ClassElement)) {
      throw StateError('element[$element] is not ClassElement');
    }

    final ProviderSource? provider =
        _componentContext.findProvider(element, name);

    if (provider is BuildInstanceSource) {
      return provider.assignString;
    }

    if (provider is AnotherComponentSource) {
      return provider.assignString;
    }

    final InjectedConstructorsVisitor visitor = InjectedConstructorsVisitor();
    element.visitChildren(visitor);

    if (visitor.injectedConstructors.isEmpty) {
      final j.Method? provideMethod =
          _componentContext.findProvideMethod(element.thisType, name);
      check(provideMethod != null,
          'provider for (${element.thisType.name}, name: $name) not found');
    }

    return '_${_generateName(element.thisType.element, name)}Provider.get()';
  }

  String _generateName(Element element, String? name) {
    if (!(element is ClassElement)) {
      throw StateError('element[$element] is not ClassElement');
    }

    if (name != null) {
      return '$name${element.thisType.name}';
    }

    return '${uncapitalize(element.thisType.name!)}';
  }

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
        final String? name =
            getNamedAnnotation(dependency.enclosingElement)?.name;
        final ProviderSource? provider =
            _componentContext.findProvider(dependency.element, name);

        if (provider is ModuleSource) {
          buildProviderFromModule(
              provider.method.element, b, _componentContext, allocator);
        } else if (provider is BuildInstanceSource) {
          print('${provider.providedClass} is BuildInstanceSource');
        } else if (provider is AnotherComponentSource) {
          print('${provider.providedClass} is AnotherComponentSource');
        } else {
          if (isCore(dependency.element) || dependency.element.isAbstract) {
            throw StateError(
              '${dependency.enclosingElement.name}.${dependency.element.name} (name: $name) not provided',
            );
          }
          if (_isBindDependency(dependency)) {
            continue;
          }
          buildProviderFromClass(
              dependency.element, b, _componentContext, allocator);
        }
      }
    }));
    return builder.build();
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
            a.providedClass.name.compareTo(b.providedClass.name));

      for (ProviderSource source in nonLazyProviders) {
        builder.statements
            .add(Code('${_generateAssignString(source.providedClass)};'));
      }
    });

    return builder.build();
  }

  bool hasNonLazyProviders() {
    return _componentContext.providerSources.any((ProviderSource source) =>
        source.annotations.any(
            (j.Annotation annotation) => annotation is j.NonLazyAnnotation));
  }

  void buildProviderFromClass(
    ClassElement element,
    BlockBuilder b,
    ComponentContext _componentContext,
    Allocator allocator,
  ) {
    _log('build provider from class: ${element.name}');

    final InjectedConstructorsVisitor visitor = InjectedConstructorsVisitor();
    element.visitChildren(visitor);

    check(visitor.injectedConstructors.length == 1,
        'not found injected constructor for ${element.name}');
    final j.InjectedConstructor injectedConstructor =
        visitor.injectedConstructors[0];
    final List<ParameterElement> parameters =
        injectedConstructor.element.parameters;

    final Expression newInstance =
        getProviderType(injectedConstructor.element, allocator)
            .newInstance(<Expression>[
      CodeExpression(Block.of(_buildProviderBody(element, <Code>[
        _buildCallMethodOrConstructor(element, parameters, _componentContext)
      ])))
    ]);

    b.addExpression(CodeExpression(Block.of(<Code>[
      Code('_${uncapitalize(element.name)}Provider = '),
      ToCodeExpression(newInstance),
    ])));
  }

  void buildProviderFromModule(
    MethodElement method,
    BlockBuilder b,
    ComponentContext _componentContext,
    Allocator allocator,
  ) {
    _log(
        'build provider from module: ${method.enclosingElement.name}.${method.name}');
    Expression expression;
    if (method.isStatic) {
      expression =
          _buildProviderFromStaticMethod(method, _componentContext, allocator);
    } else if (method.isAbstract) {
      expression = _buildProviderFromAbstractMethod(method);
    } else {
      throw StateError(
        'provided method must be abstract or static [${method.enclosingElement.name}.${method.name}]',
      );
    }

    final String? name = getNamedAnnotation(method)?.name;

    b.addExpression(CodeExpression(Block.of(<Code>[
      Code('_${_generateName(method.returnType.element!, name)}Provider  = '),
      ToCodeExpression(expression),
    ])));
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
  Expression _buildProviderFromAnotherComponent(
    MethodElement method,
    AnotherComponentSource provider,
  ) {
    final Expression newInstance =
        getProviderType(method, _allocator).newInstance(
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

    return CodeExpression(ToCodeExpression(newInstance));
  }

  Expression _buildProviderFromModule(
    MethodElement method,
    ModuleSource provider,
  ) {
    final Expression newInstance =
        getProviderType(method, _allocator).newInstance(
      <Expression>[
        CodeExpression(
          Block.of(
            _buildProviderBody(
              provider.moduleClass,
              <Code>[
                Code('${_generateAssignString(provider.providedClass)}'),
              ],
            ),
          ),
        ),
      ],
    );

    return CodeExpression(ToCodeExpression(newInstance));
  }

  Expression _buildProviderFromAbstractMethod(MethodElement method) {
    _log(
        'build provider from abstract method: ${method.enclosingElement.name}.${method.name} [${method.library.identifier}]');

    check(method.parameters.length == 1,
        'method annotates [Bind] must have 1 parameter');

    final Element rawParameter = method.parameters[0].type.element!;
    final ClassElement parameter;
    if (rawParameter is ClassElement) {
      parameter = rawParameter;
    } else {
      throw StateError('parameter must be class [${rawParameter.name}]');
    }

    final InjectedConstructorsVisitor visitor = InjectedConstructorsVisitor();
    parameter.visitChildren(visitor);

    final ProviderSource? provider =
        _componentContext.findProvider(parameter, null);

    final bool isSupertype = parameter.allSupertypes.any(
        (InterfaceType interfaceType) =>
            interfaceType.element.name ==
            method.returnType.getDisplayString(withNullability: false));

    check(isSupertype, '${method.name} bind wrong type ${method.returnType}');
    if (provider is AnotherComponentSource) {
      return _buildProviderFromAnotherComponent(method, provider);
    } else if (provider is ModuleSource) {
      return _buildProviderFromModule(method, provider);
    }

    check(visitor.injectedConstructors.length == 1,
        'not found injected constructor for ${parameter.name}');
    final j.InjectedConstructor injectedConstructor =
        visitor.injectedConstructors[0];
    final List<ParameterElement> parameters =
        injectedConstructor.element.parameters;

    final ClassElement returnClass;
    if (getBindAnnotation(method) != null) {
      final Element? bindedElement = method.parameters[0].type.element;
      assert(bindedElement is ClassElement);
      // ignore: avoid_as
      returnClass = bindedElement as ClassElement;
    } else if (getProvideAnnotation(method) != null) {
      assert(method.returnType.element is ClassElement);
      // ignore: avoid_as
      returnClass = method.returnType.element as ClassElement;
    } else {
      throw StateError(
          'unknown provided type of method ${method.getDisplayString(withNullability: false)}');
    }

    final Expression newInstance =
        getProviderType(method, _allocator).newInstance(<Expression>[
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

    return CodeExpression(ToCodeExpression(newInstance));
  }

  List<Code> _buildProviderBody(ClassElement classElement, List<Code> code) {
    final List<Code> codes = <Code>[];

    final ToCodeExpression primaryExpression =
        ToCodeExpression(CodeExpression(Block.of(code)));
    if (_isDisposable(classElement)) {
      codes.addAll(<Code>[
        const Code('() { '),
        const Code('final v = '),
        primaryExpression,
        const Code(';'),
        const Code('registerDisposable(v);'),
        const Code('return v;'),
        const Code('}'),
      ]);
    } else {
      codes.addAll(<Code>[
        const Code('() { '),
        const Code('return '),
        primaryExpression,
        const Code(';}'),
      ]);
    }
    return codes;
  }

  Expression _buildProviderFromStaticMethod(
    MethodElement method,
    ComponentContext _componentContext,
    Allocator allocator,
  ) {
    _log(
        'build provider from static method: ${method.enclosingElement.name}.${method.name}');

    assert(method.returnType.element is ClassElement);
    // ignore: avoid_as
    final ClassElement returnClass = method.returnType.element as ClassElement;
    final Element moduleClass = method.enclosingElement;
    final Expression newInstance =
        getProviderType(method, allocator).newInstance(<Expression>[
      CodeExpression(Block.of(_buildProviderBody(returnClass, <Code>[
        ToCodeExpression(
            refer(moduleClass.name!, createElementPath(moduleClass))),
        const Code('.'),
        _buildCallMethodOrConstructor(
            method, method.parameters, _componentContext)
      ])))
    ]);

    return CodeExpression(ToCodeExpression(newInstance));
  }

  Code _buildCallMethodOrConstructor(
    Element element,
    List<ParameterElement> parameters,
    ComponentContext _componentContext,
  ) {
    _log('build CallMethodOrConstructor for: ${element.name}');
    if (!(element is ClassElement) && !(element is MethodElement)) {
      throw StateError(
        'element${element.name} must be ClassElement or MethodElement',
      );
    }

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
          _componentContext.findProvider(element, null);

      if (provider is ModuleSource) {
        return Code('${_generateAssignString(provider.providedClass)}');
      }
    }

    if (parameters.isEmpty) {
      return ToCodeExpression(r(element.name!).newInstance(<Expression>[]));
    }

    final bool isPositional = parameters
        .map((ParameterElement p) => p.isPositional)
        .any((bool b) => b);
    final bool isNamed =
        parameters.map((ParameterElement p) => p.isNamed).any((bool b) => b);

    if (isPositional && isNamed) {
      throw StateError(
        'all parameters must be Positional or Named [${element.name}]',
      );
    }

    if (isPositional) {
      return ToCodeExpression(r(element.name!).newInstance(
          _buildArgumentsExpression(element, parameters, _componentContext)
              .values
              .toList()));
    }

    if (isNamed) {
      return ToCodeExpression(r(element.name!).newInstance(<Expression>[],
          _buildArgumentsExpression(element, parameters, _componentContext)));
    }

    throw StateError(
      '????',
    );
  }

  Reference getProviderType(Element element, Allocator allocator) {
    final String generic = _getGeneric(element, allocator);
    return refer(
        getAnnotations(element)
                .any((j.Annotation a) => a is j.SingletonAnnotation)
            ? 'SingletonProvider<$generic>'
            : 'Provider<$generic>',
        'package:jugger/jugger.dart');
  }

  String _getGeneric(Element element, Allocator allocator) {
    if (element is ConstructorElement) {
      final ClassElement c = element.enclosingElement;
      return allocator
          .allocate(Reference(c.thisType.name, c.librarySource.uri.toString()));
    } else if (element is MethodElement) {
      return allocator.allocate(Reference(
          _getNameFromMethod(element, allocator),
          element.returnType.element!.librarySource!.uri.toString()));
    }
    throw StateError(
        'unsupported type: ${element.name}, ${element.runtimeType}');
  }

  Constructor _buildConstructor(j.ComponentBuilder? componentBuilder) {
    return Constructor((ConstructorBuilder constructorBuilder) {
      constructorBuilder.body = const Code('_init();');

      if (componentBuilder == null) {
        constructorBuilder.name = 'create';
      } else {
        constructorBuilder.name = '_create';
        constructorBuilder.requiredParameters.addAll(componentBuilder.parameters
            .map((j.ComponentBuilderParameter parameter) {
          return Parameter((ParameterBuilder b) {
            b.toThis = true;
            final String? name =
                getNamedAnnotation(parameter.parameter.enclosingElement!)?.name;
            b.name =
                '_${_generateName(parameter.parameter.type.element!, name)}';
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
        final String? name =
            getNamedAnnotation(parameter.parameter.enclosingElement!)?.name;
        b.name = '_${_generateName(parameter.parameter.type.element!, name)}';
        b.modifier = FieldModifier.final$;
        b.type = Reference(parameter.parameter.type.name,
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
      final String? name = getNamedAnnotation(parameter)?.name;
      final CodeExpression codeExpression = CodeExpression(Block.of(<Code>[
        Code(_generateAssignString(parameter.type.element!, name)),
      ]));
      return MapEntry<String, Expression>(parameter.name, codeExpression);
    });
    return Map<String, Expression>.fromEntries(map);
  }

  void _log(String value) => _logs.add(value);
}
