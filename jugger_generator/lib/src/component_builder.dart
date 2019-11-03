import 'dart:async';

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

  String _inputLibraryPath;

  @override
  Future<Null> build(BuildStep buildStep) async {
    final String outputContents = await buildOutput(buildStep);
    if (outputContents.trim().isEmpty) {
      return;
    }
    final AssetId outputFile =
        buildStep.inputId.changeExtension('.$outputExtension');

    buildStep.writeAsString(outputFile, outputContents);
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.$inputExtension': ['.$outputExtension']
      };

  String get inputExtension => 'dart';

  String get outputExtension => 'jugger.dart';

  Future<String> buildOutput(BuildStep buildStep) async {
    Resolver resolver = buildStep.resolver;

    LibraryElement inputLibrary = await buildStep.inputLibrary;
    _inputLibraryPath = inputLibrary.library.source.uri.path;

    if (await resolver.isLibrary(buildStep.inputId)) {
      final LibraryElement lib = await buildStep.inputLibrary;

      final ComponentsVisitor visitor = ComponentsVisitor();
      lib.visitChildren(visitor);

      final LibraryBuilder target = LibraryBuilder();

      for (int i = 0; i < visitor.components.length; i++) {
        final j.Component component = visitor.components[i];

        final Graph graph = Graph.fromComponent(component);

        final List<j.ModuleAnnotation> modules = component.modules;

        target.body.add(Class((ClassBuilder classBuilder) {
          classBuilder.fields
              .addAll(_buildProvidesFields(graph.dependenciesClasses));

          classBuilder.methods.add(_buildInitMethod());

          classBuilder.methods.add(
              _buildInitProvidesMethod(graph.dependenciesClasses, modules));

          classBuilder.methods.addAll(
              _buildMembersInjectorMethods(component.methods, classBuilder));

          classBuilder.extend =
              Reference(component.element.name, createElementPath(lib));

          classBuilder.constructors.add(_buildConstructor(modules));

          classBuilder..name = 'Jugger${component.element.name}';

          classBuilder.fields.addAll(_buildModulesFields(modules));
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

  List<Field> _buildModulesFields(List<j.ModuleAnnotation> modules) {
    return modules.map((j.ModuleAnnotation moduleAnnotation) {
      return (Field((fb) {
        fb.modifier = FieldModifier.final$;
        fb.name = '_${uncapitalize(moduleAnnotation.element.name)}';
        fb.type = Reference(moduleAnnotation.element.type.name,
            createElementPath(moduleAnnotation.element));
      }));
    }).toList();
  }

  List<Field> _buildProvidesFields(List<ClassElement> classes) {
    return classes.map((ClassElement classElement) {
      return (Field((FieldBuilder b) {
        final name = classElement.thisType.name;
        b.name = '_${uncapitalize(name)}Provider';
        b.type =
            const Reference('IProvider<dynamic>', 'package:jugger/jugger.dart');
      }));
    }).toList();
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
      List<j.MemberInjectorMethod> fields, ClassBuilder classBuilder) {
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
            Code(' = _${uncapitalize(member.element.type.name)}Provider.get()'),
          ])));
        }
      });

      return builder.build();
    }).toList();
  }

  Method _buildInitProvidesMethod(
      List<ClassElement> classes, List<j.ModuleAnnotation> modules) {
    final MethodBuilder builder = MethodBuilder();
    builder.name = '_initProvides';
    builder.returns = const Reference('void');

    j.Method findProvideMethod(ClassElement element) {
      for (j.ModuleAnnotation module in modules) {
        final ProvidesVisitor visitor = ProvidesVisitor();
        module.element.visitChildren(visitor);
        for (j.Method method in visitor.methods) {
          if (method.element.returnType == element.thisType) {
            return method;
          }
        }
      }
      return null;
    }

    builder.body = Block(((BlockBuilder b) {
      for (ClassElement element in classes) {
        final j.Method provideMethod = findProvideMethod(element);

        if (provideMethod != null) {
          buildProviderFromModule(
              provideMethod.element, provideMethod.element.parameters, b);
        } else {
          buildProviderFromClass(element, b);
        }
      }
    }));
    return builder.build();
  }

  void buildProviderFromClass(ClassElement element, BlockBuilder b) {
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
        ToCodeExpression(refer(element.name, createElementPath(element))
            .newInstance(_buildArgumentsExpression(parameters))),
        const Code(';}'),
      ])),
    ]);

    b.addExpression(CodeExpression(Block.of([
      Code('_${uncapitalize(element.name)}Provider  = '),
      ToCodeExpression(newInstance),
    ])));
  }

  void buildProviderFromModule(
      MethodElement method, List<ParameterElement> parameters, BlockBuilder b) {
    final ClassElement moduleClass = method.enclosingElement;

    final InvokeExpression newInstance = getProviderType(method).newInstance([
      CodeExpression(Block.of([
        Code('() { return _${uncapitalize(moduleClass.thisType.name)}.'),
        ToCodeExpression(refer(method.name)
            .newInstance(_buildArgumentsExpression(parameters))),
        const Code(';}'),
      ])),
    ]);

    b.addExpression(CodeExpression(Block.of([
      Code('_${uncapitalize(method.returnType.name)}Provider  = '),
      ToCodeExpression(newInstance),
    ])));
  }

  Reference getProviderType(Element element) {
    return refer(
        getAnnotations(element)
                .any((j.Annotation a) => a is j.SingletonAnnotation)
            ? 'SingletonProvider<dynamic>'
            : 'Provider<dynamic>',
        'package:jugger/jugger.dart');
  }

  Constructor _buildConstructor(List<j.ModuleAnnotation> modules) {
    return Constructor((ConstructorBuilder constructorBuilder) {
      constructorBuilder.body = const Code('_init();');
      constructorBuilder.optionalParameters
          .addAll(modules.map((j.ModuleAnnotation moduleAnnotation) {
        return Parameter((ParameterBuilder parameterBuilder) {
          ClassElement element = moduleAnnotation.element;
          parameterBuilder.named = true;
          parameterBuilder.annotations
              .add(const Reference('required', 'package:meta/meta.dart'));
          parameterBuilder.name = uncapitalize(element.name);
          parameterBuilder.type =
              Reference(element.type.name, createElementPath(element));
        });
      }).toList());
      constructorBuilder.name = 'create';
      constructorBuilder.initializers
          .addAll(modules.map((j.ModuleAnnotation moduleAnnotation) {
        return Code(
            '_${uncapitalize(moduleAnnotation.element.thisType.name)} = ${uncapitalize(moduleAnnotation.element.thisType.name)}');
      }).toList());
    });
  }

  Iterable<Expression> _buildArgumentsExpression(
      List<ParameterElement> parameters) {
    if (parameters.isEmpty) {
      return <Expression>[];
    }

    return parameters.map((ParameterElement parameter) {
      return CodeExpression(Block.of([
        Code('${'_${uncapitalize(parameter.type.name)}Provider'}.get()'),
      ]));
    });
  }
}
