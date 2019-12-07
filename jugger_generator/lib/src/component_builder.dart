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
              .addAll(_buildProvidesFields(graph.dependenciesClasses, graph));
          classBuilder.fields.addAll(_buildConstructorFields(componentBuilder));

          classBuilder.methods.add(_buildInitMethod());

          classBuilder.methods.add(
              _buildInitProvidesMethod(graph.dependenciesClasses, modules, graph));

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
                      final CodeExpression codeExpression = CodeExpression(
                          Block.of([
                            Code('_${uncapitalize(parameter.toString())}'),
                          ]));
                      return codeExpression;
                    });

                    b.addExpression(CodeExpression(Block.of(
                        componentBuilder.parameters.map((
                            j.ComponentBuilderParameter parameter) {
                          return Code(
                              'assert(${parameter.fieldName} != null); ');
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
                    b.addExpression(CodeExpression(Block.of([
                      Code('_${uncapitalize(p.toString())} = ${p.parameter
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
            b.name = '_${uncapitalize(parameter.toString())}';
          });
        }));

        return classBuilder;
      }));
    }
  }

  List<Field> _buildProvidesFields(List<ClassElement> classes, Graph graph) {
    final List<Field> fields = <Field>[];

    for (ClassElement element in classes) {
      final ProviderSource provider = graph.findProvider(element);

      if (!(provider is BuildInstanceSource)) {
        fields.add(Field((FieldBuilder b) {
          final name = element.thisType.name;
          b.name = '_${uncapitalize(name)}Provider';
          b.type =
          const Reference('IProvider<dynamic>', 'package:jugger/jugger.dart');
        }));
      } else {
        print('skip generation provide field for ${provider}');
      }
    }

    return fields;
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
      assert(method.element.parameters.length == 1);

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
          b.addExpression(CodeExpression(Block.of([
            Code('${parameterElement.name}.${member.element.name}'),
            Code(' = ${_generateAssignString(
                member.element.type.element, graph)}'),
          ])));
        }
      });

      return builder.build();
    }).toList();
  }

  String _generateAssignString(ClassElement element, Graph graph) {
    final ProviderSource provider = graph.findProvider(element);

    if (provider is BuildInstanceSource) {
      return provider.assignString;
    }

    return '_${uncapitalize(element.type.name)}Provider.get()';
  }

  Method _buildInitProvidesMethod(
      List<ClassElement> classes, List<j.ModuleAnnotation> modules,
      Graph graph) {
    final MethodBuilder builder = MethodBuilder();
    builder.name = '_initProvides';
    builder.returns = const Reference('void');

    // ignore: unnecessary_parenthesis
    builder.body = Block(((BlockBuilder b) {
      for (ClassElement element in classes) {
        final ProviderSource provider = graph.findProvider(element);

        if (provider is ModuleSource) {
          buildProviderFromModule(provider.method.element, b, graph);
        } else if (provider is BuildInstanceSource) {
          print('${provider.providedClass} is BuildInstanceSource');
        } else {
          buildProviderFromClass(element, b, graph);
        }
      }
    }));
    return builder.build();
  }

  void buildProviderFromClass(ClassElement element, BlockBuilder b,
      Graph graph) {
    final InjectedConstructorsVisitor visitor = InjectedConstructorsVisitor();
    element.visitChildren(visitor);

    assert(visitor.injectedConstructors.length == 1,
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

    b.addExpression(CodeExpression(Block.of([
      Code('_${uncapitalize(method.returnType.name)}Provider  = '),
      ToCodeExpression(expression),
    ])));
  }

  InvokeExpression _buildProviderFromAbstractMethod(MethodElement method,
      Graph graph) {
    assert(method.parameters.length ==
        1, 'method annotates [Bind] must have 1 parameter');

    final ClassElement parameter = method.parameters[0].type.element;

    final InjectedConstructorsVisitor visitor = InjectedConstructorsVisitor();
    parameter.visitChildren(visitor);

    assert(visitor.injectedConstructors.length == 1,
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
            b.name = '_${uncapitalize(parameter.toString())}';
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
        b.name = '_${uncapitalize(parameter.toString())}';
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
      final CodeExpression codeExpression = CodeExpression(Block.of([
        Code(_generateAssignString(parameter.type.element, graph)),
      ]));
      return MapEntry<String, Expression>(parameter.name, codeExpression);
    });
    return Map<String, Expression>.fromEntries(map);
  }
}
