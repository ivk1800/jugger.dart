import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
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
    if (outputContents.trim().isEmpty) {
      return Future<void>.value(null);
    }
    final AssetId outputFile =
        buildStep.inputId.changeExtension('.$outputExtension');

    buildStep.writeAsString(outputFile, outputContents);

    return Future<void>.value(null);
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.$inputExtension': ['.$outputExtension']
      };

  String get inputExtension => 'dart';

  String get outputExtension => 'jugger.dart';

  Future<String> buildOutput(BuildStep buildStep) async {
    Resolver resolver = buildStep.resolver;

    if (await resolver.isLibrary(buildStep.inputId)) {
      final LibraryElement lib = await buildStep.inputLibrary;

      final ComponentBuildersVisitor componentBuildersVisitor = ComponentBuildersVisitor();
      lib.visitChildren(componentBuildersVisitor);

      final ComponentsVisitor visitor = ComponentsVisitor();
      lib.visitChildren(visitor);

      final LibraryBuilder target = LibraryBuilder();

      _generateComponentBuilders(target, lib, componentBuildersVisitor.componentBuilders);

      for (int i = 0; i < visitor.components.length; i++) {
        final j.Component component = visitor.components[i];

        final j.ComponentBuilder componentBuilder = componentBuildersVisitor
            .componentBuilders.firstWhere((j.ComponentBuilder b) {
          return b.componentClass.name == component.element.name;
        }, orElse: () => null);

        final Graph graph = Graph.fromComponent(component, componentBuilder);

        final List<j.ModuleAnnotation> modules = component.modules;

        target.body.add(Class((ClassBuilder classBuilder) {
          classBuilder.fields
              .addAll(_buildProvidesFields(graph.dependencies, graph));
          classBuilder.fields.addAll(_buildConstructorFields(componentBuilder));

          classBuilder.methods.addAll(_buildProvideMethods(graph));

          classBuilder.methods.add(_buildInitMethod());

          classBuilder.methods.add(
              _buildInitProvidesMethod(graph.dependencies, modules, graph));

          classBuilder.methods.addAll(
              _buildMembersInjectorMethods(component.methods, classBuilder, graph));

          classBuilder.implements.add(Reference(component.element.name, createElementPath(lib)));

          classBuilder.constructors.add(_buildConstructor(componentBuilder));

          classBuilder..name = 'Jugger${component.element.name}';

          return classBuilder;
        }));
      }

      return Future.value(DartFormatter().format(
        target.build().accept(DartEmitter.scoped()).toString(),
      ));
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
        classBuilder.methods.addAll(
            componentBuilder.methods.map((MethodElement m) {
              return Method((MethodBuilder b) {
                b.annotations.add(const CodeExpression(Code('override')));
                b.name = m.name;
                b.returns = Reference(
                    m.returnType.name, createElementPath(m.returnType.element));
                b.requiredParameters.addAll(
                    m.parameters.map((ParameterElement pe) {
                      return Parameter((ParameterBuilder parameterBuilder) {
                        parameterBuilder.name = pe.name;
                        parameterBuilder.type =
                            Reference(pe.type.name,
                                createElementPath(pe.type.element));
                      });
                    }));

                b.body = Block((b) {
                  if (m.name == 'build') {
                    final Iterable<Expression> map = componentBuilder.parameters
                        .map((j.ComponentBuilderParameter parameter) {
                      final String name = getNamedAnnotation(parameter.parameter.enclosingElement)?.name;
                      final CodeExpression codeExpression = CodeExpression(
                          Block.of([
                            Code('_${_generateName(parameter.parameter.type.element, name)}'),
                          ]));
                      return codeExpression;
                    });

                    b.addExpression(CodeExpression(Block.of(
                        componentBuilder.parameters.map((
                            j.ComponentBuilderParameter parameter) {
                          final String name = getNamedAnnotation(parameter.parameter.enclosingElement)?.name;
                          return Code(
                              'assert(_${_generateName(parameter.parameter.type.element, name)} != null); ');
                        }))));

                    final newInstance = refer(
                        'Jugger${m.returnType.name}._create').newInstance(map);


                    b.addExpression(CodeExpression(Block.of([
                      const Code('return '),
                      ToCodeExpression(newInstance)
                    ])));
                  } else {
                    final j.ComponentBuilderParameter p = j
                        .ComponentBuilderParameter(parameter: m.parameters[0]);
                    final String name = getNamedAnnotation(p.parameter.enclosingElement)?.name;
                    b.addExpression(CodeExpression(Block.of([
                      Code('_${_generateName(p.parameter.type.element, name)} = ${p.parameter
                          .name}; return this'),
                    ])));
                  }
                });
              });
            }));
        classBuilder.fields.addAll(componentBuilder.parameters.map((
            j.ComponentBuilderParameter parameter) {
          return Field((FieldBuilder b) {
            b.type = Reference(parameter.parameter.type.name,
                createElementPath(parameter.parameter.type.element));
            final String name = getNamedAnnotation(parameter.parameter.enclosingElement)?.name;
            b.name = '_${_generateName(parameter.parameter.type.element, name)}';
          });
        }));

        return classBuilder;
      }));
    }
  }

  List<Field> _buildProvidesFields(List<Dependency> dependencies, Graph graph) {
    final List<Field> fields = <Field>[];

    for (Dependency dependency in dependencies) {
      final ProviderSource provider = graph.findProvider(dependency.element);

      if (!(provider is BuildInstanceSource) &&
          !(provider is AnotherComponentSource)) {
        fields.add(Field((FieldBuilder b) {
          final String name = getNamedAnnotation(dependency.enclosingElement)?.name;
          b.name = '_${_generateName(dependency.element, name)}Provider';
          b.type =
          const Reference('IProvider<dynamic>', 'package:jugger/jugger.dart');
        }));
      } else {
        print('skip generation provide field for ${provider}');
      }
    }

    return fields;
  }

  List<Method> _buildProvideMethods(Graph graph) {
    final List<MethodElement> methods = graph.component.provideMethod;
    final List<Method> newProperties = <Method>[];

    for (MethodElement method in methods) {
      final m = Method((MethodBuilder b) {
        b.annotations.add(const CodeExpression(Code('override')));
        b.name = method.name;
        b.returns = Reference(method.returnType.name, createElementPath(method.returnType.element));

        final String name = getNamedAnnotation(method)?.name;
        final ProviderSource providerSource = graph.findProvider(method.returnType.element, name);

        check(providerSource != null, '${method.returnType.element.name} not provided');

        b.body = Code('return ${_generateAssignString(method.returnType.element, graph)};');
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

  List<Method> _buildMembersInjectorMethods(
      List<j.MemberInjectorMethod> fields, ClassBuilder classBuilder,
      Graph graph) {
    return fields.map((j.MemberInjectorMethod method) {
      MethodBuilder builder = MethodBuilder();
      builder.name = method.element.name;
      builder.annotations.add(const CodeExpression(Code('override')));
      builder.returns = const Reference('void');
      check(method.element.parameters.length == 1,
          'method ${method.element.name} must have 1 parameter');

      final ParameterElement parameterElement = method.element.parameters[0];

      builder.requiredParameters.add(Parameter((b) {
        b.name = uncapitalize(parameterElement.name);
        b.type = Reference(parameterElement.type.name,
            createElementPath(parameterElement.type.element));
      }));

      InjectedMembersVisitor visitor = InjectedMembersVisitor();
      parameterElement.type.element.visitChildren(visitor);

      builder.body = Block((b) {
        for (j.InjectedMember member in visitor.members) {
          final String name = getNamedAnnotation(member.element)?.name;
          b.addExpression(CodeExpression(Block.of([
            Code('${parameterElement.name}.${member.element.name}'),
            Code(' = ${_generateAssignString(
                member.element.type.element, graph, name)}'),
          ])));
        }
      });

      return builder.build();
    }).toList();
  }

  String _generateAssignString(ClassElement element, Graph graph, [String name]) {
    final ProviderSource provider = graph.findProvider(element, name);

    if (provider is BuildInstanceSource) {
      return provider.assignString;
    }

    if (provider is AnotherComponentSource) {
      return provider.assignString;
    }

    final InjectedConstructorsVisitor visitor = InjectedConstructorsVisitor();
    element.visitChildren(visitor);

    if (visitor.injectedConstructors.isEmpty) {
      final j.Method provideMethod = graph.findProvideMethod(element.thisType, name);
      check(provideMethod != null, 'provider for (${element.thisType.name}, name: $name) not found');
    }

    return '_${_generateName(element.thisType.element, name)}Provider.get()';
  }

  String _generateName(ClassElement element, String name) {
    if (name != null) {
      return '$name${element.thisType.name}';
    }

    return '${uncapitalize(element.thisType.name)}';
  }

  Method _buildInitProvidesMethod(
  List<Dependency> dependencies, List<j.ModuleAnnotation> modules,
      Graph graph) {
    final MethodBuilder builder = MethodBuilder();
    builder.name = '_initProvides';
    builder.returns = const Reference('void');

    // ignore: unnecessary_parenthesis
    builder.body = Block(((BlockBuilder b) {
      for (Dependency dependency in dependencies) {
        final String name = getNamedAnnotation(dependency.enclosingElement)?.name;
        final ProviderSource provider = graph.findProvider(dependency.element, name);

        if (provider is ModuleSource) {
          buildProviderFromModule(provider.method.element, b, graph);
        } else if (provider is BuildInstanceSource) {
          print('${provider.providedClass} is BuildInstanceSource');
        } else if (provider is AnotherComponentSource) {
          print('${provider.providedClass} is AnotherComponentSource');
        }  else {
          if (isCore(dependency.element) ||
              dependency.element.isAbstract) {
            throw StateError(
              '${dependency.enclosingElement.name}.${dependency.element.name} (name: $name) not provided',
            );
          }
          buildProviderFromClass(dependency.element, b, graph);
        }
      }
    }));
    return builder.build();
  }

  void buildProviderFromClass(ClassElement element, BlockBuilder b,
      Graph graph) {
    final InjectedConstructorsVisitor visitor = InjectedConstructorsVisitor();
    element.visitChildren(visitor);

    check(visitor.injectedConstructors.length == 1,
        'not found injected constructor for ${element.name}');
    final j.InjectedConstructor injectedConstructor =
        visitor.injectedConstructors[0];
    final List<ParameterElement> parameters =
        injectedConstructor.element.parameters;

    final InvokeExpression newInstance =
        getProviderType(injectedConstructor.element).newInstance([
      CodeExpression(Block.of([
        const Code('() { return '),
        _buildCallMethodOrConstructor(element, parameters, graph),
        const Code(';}'),
      ])),
    ]);

    b.addExpression(CodeExpression(Block.of([
      Code('_${uncapitalize(element.name)}Provider  = '),
      ToCodeExpression(newInstance),
    ])));
  }

  void buildProviderFromModule(MethodElement method, BlockBuilder b,
      Graph graph) {
    InvokeExpression expression;
    if (method.isStatic) {
      expression = _buildProviderFromStaticMethod(method, graph);
    } else if (method.isAbstract) {
      expression = _buildProviderFromAbstractMethod(method, graph);
    } else {
      throw StateError(
        'provided method must be abstract or static [${method.enclosingElement
            .name}.${method.name}]',
      );
    }

    final String name = getNamedAnnotation(method)?.name;

    b.addExpression(CodeExpression(Block.of([
      Code('_${_generateName(method.returnType.element, name)}Provider  = '),
      ToCodeExpression(expression),
    ])));
  }

  InvokeExpression _buildProviderFromAbstractMethod(MethodElement method,
      Graph graph) {
    check(method.parameters.length ==
        1, 'method annotates [Bind] must have 1 parameter');

    final ClassElement parameter = method.parameters[0].type.element;

    final InjectedConstructorsVisitor visitor = InjectedConstructorsVisitor();
    parameter.visitChildren(visitor);

    check(visitor.injectedConstructors.length == 1,
    'not found injected constructor for ${parameter.name}');
    final j.InjectedConstructor injectedConstructor =
    visitor.injectedConstructors[0];
    final List<ParameterElement> parameters =
        injectedConstructor.element.parameters;

    return getProviderType(method).newInstance([
      CodeExpression(Block.of([
        const Code('() { return '),
        _buildCallMethodOrConstructor(parameter, parameters, graph),
        const Code(';}'),
      ])),
    ]);
  }

  InvokeExpression _buildProviderFromStaticMethod(MethodElement method,
      Graph graph) {
    final ClassElement moduleClass = method.enclosingElement;
    return getProviderType(method).newInstance([
      CodeExpression(Block.of([
        const Code('() { return '),
        ToCodeExpression(
            refer(moduleClass.name, createElementPath(moduleClass))),
        const Code('.'),
        _buildCallMethodOrConstructor(method, method.parameters, graph),
        const Code(';}'),
      ])),
    ]);
  }

  ToCodeExpression _buildCallMethodOrConstructor(Element element,
      List<ParameterElement> parameters, Graph graph) {

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

    if (parameters.isEmpty) {
      return ToCodeExpression(r(element.name).newInstance([]));
    }

    final bool isPositional = parameters.map((ParameterElement p) => p.isPositional).any((bool b) => b);
    final bool isNamed = parameters.map((ParameterElement p) => p.isNamed).any((bool b) => b);

    if (isPositional && isNamed) {
      throw StateError(
        'all parameters must be Positional or Named [${element.name}]',
      );
    }

    if (isPositional) {
      return ToCodeExpression(r(element.name).newInstance(_buildArgumentsExpression(parameters, graph).values.toList()));
    }

    if (isNamed) {
      return ToCodeExpression(r(element.name).newInstance([], _buildArgumentsExpression(parameters, graph)));
    }

    throw StateError(
      '????',
    );
  }

  Reference getProviderType(Element element) {
    return refer(
        getAnnotations(element)
                .any((j.Annotation a) => a is j.SingletonAnnotation)
            ? 'SingletonProvider<dynamic>'
            : 'Provider<dynamic>',
        'package:jugger/jugger.dart');
  }

  Constructor _buildConstructor(j.ComponentBuilder componentBuilder) {
    return Constructor((ConstructorBuilder constructorBuilder) {
      constructorBuilder.body = const Code('_init();');

      if (componentBuilder == null) {
        constructorBuilder.name = 'create';
      } else {
        constructorBuilder.name = '_create';
        constructorBuilder.requiredParameters.addAll(componentBuilder.parameters.map((j.ComponentBuilderParameter parameter) {
          return Parameter((ParameterBuilder b) {
            b.toThis = true;
            final String name = getNamedAnnotation(parameter.parameter.enclosingElement)?.name;
            b.name = '_${_generateName(parameter.parameter.type.element, name)}';
          });
        }));
      }
    });
  }

  List<Field> _buildConstructorFields(j.ComponentBuilder componentBuilder) {
    if (componentBuilder == null) {
      return <Field>[];
    }

    return componentBuilder.parameters.map((j.ComponentBuilderParameter parameter) {
      // ignore: unnecessary_parenthesis
      return (Field((FieldBuilder b) {
        final String name = getNamedAnnotation(parameter.parameter.enclosingElement)?.name;
        b.name = '_${_generateName(parameter.parameter.type.element, name)}';
        b.modifier = FieldModifier.final$;
        b.type = Reference(parameter.parameter.type.name,
            createElementPath(parameter.parameter.type.element));
      }));
    }).toList();
  }

  Map<String, Expression> _buildArgumentsExpression(
      List<ParameterElement> parameters, Graph graph) {
    if (parameters.isEmpty) {
      return HashMap<String, Expression>();
    }

    final Iterable<MapEntry<String, Expression>> map = parameters.map((ParameterElement parameter) {
      final String name = getNamedAnnotation(parameter)?.name;
      final CodeExpression codeExpression = CodeExpression(Block.of([
        Code(_generateAssignString(parameter.type.element, graph, name)),
      ]));
      return MapEntry<String, Expression>(parameter.name, codeExpression);
    });
    return Map<String, Expression>.fromEntries(map);
  }
}
