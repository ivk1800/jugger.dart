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
import 'graph.dart';
import 'visitors.dart';

class ComponentBuilder extends Builder {
  ComponentBuilder();

  @override
  Future<void> build(BuildStep buildStep) async {
    final String outputContents = await buildOutput(buildStep);
    if (outputContents.trim().isEmpty || _isTestAsset(buildStep.inputId)) {
      return Future<void>.value(null);
    }
    final AssetId outputFile =
        buildStep.inputId.changeExtension('.$outputExtension');

    buildStep.writeAsString(outputFile, outputContents);

    return Future<void>.value(null);
  }

  @override
  Map<String, List<String>> get buildExtensions => <String, List<String>>{
        '.$inputExtension': <String>['.$outputExtension']
      };

  String get inputExtension => 'dart';

  String get outputExtension => 'jugger.dart';

  Future<String> buildOutput(BuildStep buildStep) async {
    final Resolver resolver = buildStep.resolver;

    if (await resolver.isLibrary(buildStep.inputId)) {
      final Allocator allocator = Allocator.simplePrefixing();

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

        final Graph graph = Graph.fromComponent(component, componentBuilder);

        final List<j.ModuleAnnotation> modules = component.modules;

        target.body.add(Class((ClassBuilder classBuilder) {
          classBuilder.fields.addAll(
              _buildProvidesFields(graph.dependencies, graph, allocator));
          classBuilder.fields.addAll(_buildConstructorFields(componentBuilder));

          classBuilder.methods.addAll(_buildProvideMethods(graph));

          classBuilder.methods.add(_buildInitMethod());

          classBuilder.methods.add(_buildInitProvidesMethod(
              graph.dependencies, modules, graph, allocator));

          classBuilder.methods.addAll(_buildMembersInjectorMethods(
              component.methods, classBuilder, graph));

          classBuilder.implements
              .add(Reference(component.element.name, createElementPath(lib)));

          classBuilder.constructors.add(_buildConstructor(componentBuilder));

          classBuilder..name = 'Jugger${component.element.name}';
        }));
      }

      final String string =
          target.build().accept(DartEmitter(allocator)).toString();

      final String finalString = string.isEmpty
          ? ''
          : '// ignore_for_file: implementation_imports \n'
              '// ignore_for_file: prefer_const_constructors \n'
              '// ignore_for_file: always_specify_types \n'
              '// ignore_for_file: directives_ordering \n'
              ' $string';

      return Future<String>.value(DartFormatter().format(finalString));
    }

    throw StateError(
      'is not library',
    );
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
      List<Dependency> dependencies, Graph graph, Allocator allocator) {
    final List<Field> fields = <Field>[];

    for (Dependency dependency in dependencies) {
      final ProviderSource? provider =
          graph.findProvider(dependency.element, dependency.named);

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

    return fields;
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

  List<Method> _buildProvideMethods(Graph graph) {
    final List<MethodElement> methods = graph.component.provideMethod;
    final List<Method> newProperties = <Method>[];

    for (MethodElement method in methods) {
      print(
          'build provide method for: ${method.enclosingElement.name}.${method.name}');
      final Method m = Method((MethodBuilder b) {
        b.annotations.add(const CodeExpression(Code('override')));
        b.name = method.name;
        b.returns = Reference(method.returnType.name,
            createElementPath(method.returnType.element!));

        final String? name = getNamedAnnotation(method)?.name;
        final ProviderSource? providerSource =
            graph.findProvider(method.returnType.element!, name);

        check(providerSource != null,
            '${method.returnType.element!.name} not provided');

        b.body = Code(
            'return ${_generateAssignString(method.returnType.element!, graph)};');
      });
      newProperties.add(m);
    }

    return newProperties;
  }

  Method _buildInitMethod() {
    return Method((MethodBuilder b) {
      b.name = '_init';
      b.body = const Code(''
          '_initProvides();');
      b.returns = const Reference('void');
    });
  }

  List<Method> _buildMembersInjectorMethods(List<j.MemberInjectorMethod> fields,
      ClassBuilder classBuilder, Graph graph) {
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
          print('build provide method for member: ${member.element}');
          final String? name = getNamedAnnotation(member.element)?.name;
          b.addExpression(CodeExpression(Block.of(<Code>[
            Code('${parameterElement.name}.${member.element.name}'),
            Code(
                ' = ${_generateAssignString(member.element.type.element!, graph, name)}'),
          ])));
        }
      });

      return builder.build();
    }).toList();
  }

  String _generateAssignString(Element element, Graph graph, [String? name]) {
    if (!(element is ClassElement)) {
      throw StateError('element[$element] is not ClassElement');
    }

    final ProviderSource? provider = graph.findProvider(element, name);

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
          graph.findProvideMethod(element.thisType, name);
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

  Method _buildInitProvidesMethod(List<Dependency> dependencies,
      List<j.ModuleAnnotation> modules, Graph graph, Allocator allocator) {
    final MethodBuilder builder = MethodBuilder();
    builder.name = '_initProvides';
    builder.returns = const Reference('void');

    // ignore: unnecessary_parenthesis
    builder.body = Block(((BlockBuilder b) {
      for (Dependency dependency in dependencies) {
        print(
            'build provider for dependency: ${dependency.enclosingElement.name}.${dependency.element.name}');
        final String? name =
            getNamedAnnotation(dependency.enclosingElement)?.name;
        final ProviderSource? provider =
            graph.findProvider(dependency.element, name);

        if (provider is ModuleSource) {
          buildProviderFromModule(provider.method.element, b, graph, allocator);
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
          buildProviderFromClass(dependency.element, b, graph, allocator);
        }
      }
    }));
    return builder.build();
  }

  void buildProviderFromClass(
      ClassElement element, BlockBuilder b, Graph graph, Allocator allocator) {
    print('build provider from class: ${element.name}');

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
      CodeExpression(Block.of(<Code>[
        const Code('() { return '),
        _buildCallMethodOrConstructor(element, parameters, graph),
        const Code(';}'),
      ])),
    ]);

    b.addExpression(CodeExpression(Block.of(<Code>[
      Code('_${uncapitalize(element.name)}Provider  = '),
      ToCodeExpression(newInstance),
    ])));
  }

  void buildProviderFromModule(
      MethodElement method, BlockBuilder b, Graph graph, Allocator allocator) {
    print(
        'build provider from module: ${method.enclosingElement.name}.${method.name}');
    Expression expression;
    if (method.isStatic) {
      expression = _buildProviderFromStaticMethod(method, graph, allocator);
    } else if (method.isAbstract) {
      expression = _buildProviderFromAbstractMethod(method, graph, allocator);
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

  Expression _buildProviderFromAbstractMethod(
      MethodElement method, Graph graph, Allocator allocator) {
    print(
        'build provider from abstract method: ${method.enclosingElement.name}.${method.name}');

    check(method.parameters.length == 1,
        'method annotates [Bind] must have 1 parameter');

    final Element parameter = method.parameters[0].type.element!;

    final InjectedConstructorsVisitor visitor = InjectedConstructorsVisitor();
    parameter.visitChildren(visitor);

    check(visitor.injectedConstructors.length == 1,
        'not found injected constructor for ${parameter.name}');
    final j.InjectedConstructor injectedConstructor =
        visitor.injectedConstructors[0];
    final List<ParameterElement> parameters =
        injectedConstructor.element.parameters;

    return getProviderType(method, allocator).newInstance(<Expression>[
      CodeExpression(Block.of(<Code>[
        const Code('() { return '),
        _buildCallMethodOrConstructor(parameter, parameters, graph),
        const Code(';}'),
      ])),
    ]);
  }

  Expression _buildProviderFromStaticMethod(
      MethodElement method, Graph graph, Allocator allocator) {
    print(
        'build provider from static method: ${method.enclosingElement.name}.${method.name}');

    final Element moduleClass = method.enclosingElement;
    return getProviderType(method, allocator).newInstance(<Expression>[
      CodeExpression(Block.of(<Code>[
        const Code('() { return '),
        ToCodeExpression(
            refer(moduleClass.name, createElementPath(moduleClass))),
        const Code('.'),
        _buildCallMethodOrConstructor(method, method.parameters, graph),
        const Code(';}'),
      ])),
    ]);
  }

  Code _buildCallMethodOrConstructor(
      Element element, List<ParameterElement> parameters, Graph graph) {
    print('build CallMethodOrConstructor for: ${element.name}');
    if (!(element is ClassElement) && !(element is MethodElement)) {
      throw StateError(
        'element${element.name} must be ClassElement or MethodElement',
      );
    }

    Reference r(String symbol) {
      if (element is MethodElement) {
        return refer(element.name);
      }
      return refer(element.name, createElementPath(element));
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
      final ProviderSource? provider = graph.findProvider(element, null);

      if (provider is ModuleSource) {
        return Code('${_generateAssignString(provider.providedClass, graph)}');
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
          _buildArgumentsExpression(element, parameters, graph)
              .values
              .toList()));
    }

    if (isNamed) {
      return ToCodeExpression(r(element.name!).newInstance(<Expression>[],
          _buildArgumentsExpression(element, parameters, graph)));
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
      Element forElement, List<ParameterElement> parameters, Graph graph) {
    print('build arguments for ${forElement.name}: $parameters');

    if (parameters.isEmpty) {
      return HashMap<String, Expression>();
    }

    final Iterable<MapEntry<String, Expression>> map =
        parameters.map((ParameterElement parameter) {
      final String? name = getNamedAnnotation(parameter)?.name;
      final CodeExpression codeExpression = CodeExpression(Block.of(<Code>[
        Code(_generateAssignString(parameter.type.element!, graph, name)),
      ]));
      return MapEntry<String, Expression>(parameter.name, codeExpression);
    });
    return Map<String, Expression>.fromEntries(map);
  }

  bool _isTestAsset(AssetId inputId) {
    return inputId.pathSegments.first == 'test';
  }
}
