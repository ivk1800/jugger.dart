import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:jugger/jugger.dart' as jugger;

import 'check_unused_providers.dart';
import 'classes.dart' as j;
import 'component_context.dart';
import 'dart_type_ext.dart';
import 'errors_glossary.dart';
import 'global_config.dart';
import 'jugger_error.dart';
import 'messages.dart';
import 'tag.dart';
import 'utils.dart';
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

  static const List<String> ignores = <String>[
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
      log.shout('\x1B[94m$message\x1B[0m');
      log.shout((e as Error).stackTrace);
      rethrow;
    }
  }

  Future<String> _buildOutput(BuildStep buildStep) async {
    final Resolver resolver = buildStep.resolver;

    if (await resolver.isLibrary(buildStep.inputId)) {
      _allocator = Allocator.simplePrefixing();

      final LibraryElement lib = await buildStep.inputLibrary;

      final List<j.Component> components = lib.getComponents();
      final LibraryBuilder target = LibraryBuilder();

      final List<j.ComponentBuilder> componentBuilders =
          lib.getComponentBuilders();

      _generateComponentBuilders(target, lib, componentBuilders);

      for (int i = 0; i < components.length; i++) {
        final j.Component component = components[i];
        _componentType = component.element.thisType;

        final j.ComponentBuilder? componentBuilder =
            componentBuilders.firstWhereOrNull((j.ComponentBuilder b) {
          return b.componentClass.name == component.element.name;
        });

        _componentContext = ComponentContext(
          component: component,
          componentBuilder: componentBuilder,
        );
        _logs.clear();

        target.body.add(Class((ClassBuilder classBuilder) {
          classBuilder.fields.addAll(_buildProvidesFields());
          classBuilder.fields.addAll(_buildConstructorFields(componentBuilder));
          _log('build for component: ${component.element.toNameWithPath()}');
          classBuilder.methods.addAll(_buildProvideMethods());
          classBuilder.methods.addAll(_buildProvideProperties());

          if (hasNonLazyProviders()) {
            classBuilder.methods.add(_buildInitNonLazyMethod());
          }

          classBuilder.methods.addAll(_buildMembersInjectorMethods(
              component.memberInjectors, classBuilder));

          classBuilder.implements
              .add(Reference(component.element.name, createElementPath(lib)));

          classBuilder.constructors.add(_buildConstructor(componentBuilder));

          classBuilder.name = _createComponentName(component.element.name);
        }));
      }

      final String fileText =
          target.build().accept(DartEmitter(allocator: _allocator)).toString();

      if (globalConfig.checkUnusedProviders) {
        checkUnusedProviders(fileText);
      }

      final String finalFileText = fileText.isEmpty
          ? ''
          : '${ignores.map((String line) => '// $line').join('\n')}\n$fileText';
      return DartFormatter().format(finalFileText);
    }

    return '';
  }

  void _generateComponentBuilders(
    LibraryBuilder target,
    LibraryElement lib,
    List<j.ComponentBuilder> componentBuilders,
  ) {
    for (int i = 0; i < componentBuilders.length; i++) {
      final j.ComponentBuilder componentBuilder = componentBuilders[i];
      target.body.add(_buildComponentBuilderClass(componentBuilder, lib));
    }
  }

  /// Returns a class of component builder.
  Class _buildComponentBuilderClass(
    j.ComponentBuilder componentBuilder,
    LibraryElement lib,
  ) {
    return Class((ClassBuilder classBuilder) {
      classBuilder.name =
          '${_createComponentName(componentBuilder.componentClass.name)}Builder';

      classBuilder.implements.add(
        refer(componentBuilder.element.name, createElementPath(lib)),
      );
      classBuilder.methods.addAll(
        componentBuilder.methods.map(
          (MethodElement m) {
            return _buildComponentBuilderMethod(componentBuilder, m);
          },
        ),
      );
      classBuilder.fields.addAll(
        componentBuilder.parameters.map(
          (j.ComponentBuilderParameter parameter) {
            return _buildComponentParameter(parameter);
          },
        ),
      );
    });
  }

  /// Returns component argument field which is taken from the component
  /// builder.
  Field _buildComponentParameter(j.ComponentBuilderParameter parameter) {
    return Field((FieldBuilder b) {
      b.type = refer('${_allocateTypeName(parameter.parameter.type)}?');
      final Tag? tag = parameter.parameter.enclosingElement!.getQualifierTag();
      b.name = '_${_generateFieldName(
        parameter.parameter.type,
        tag?._toAssignTag(),
      )}';
    });
  }

  /// Returns the method body of the component builder, method can be any.
  Method _buildComponentBuilderMethod(
    j.ComponentBuilder componentBuilder,
    MethodElement method,
  ) {
    return Method((MethodBuilder builder) {
      builder.annotations.add(_overrideAnnotationExpression);
      builder.name = method.name;
      builder.returns = refer(
        method.returnType.getName(),
        createElementPath(method.returnType.element!),
      );
      builder.requiredParameters.addAll(
        method.parameters.map(
          (ParameterElement pe) {
            return Parameter((ParameterBuilder parameterBuilder) {
              parameterBuilder.name = pe.name;
              parameterBuilder.type = refer(_allocateTypeName(pe.type));
            });
          },
        ),
      );

      if (method.name == 'build') {
        builder.body = _buildComponentBuilderBuildMethodBody(
          componentBuilder,
          method.returnType,
        );
      } else {
        builder.body = _buildComponentBuilderMethodBody(method);
      }
    });
  }

  /// Returns the method body of the component builder, should not be a method
  /// named 'build', there is a separate method to generate such a method.
  Code _buildComponentBuilderMethodBody(MethodElement method) {
    return Block((BlockBuilder builder) {
      final j.ComponentBuilderParameter p =
          j.ComponentBuilderParameter(parameter: method.parameters[0]);
      final Tag? tag = p.parameter.enclosingElement!.getQualifierTag();
      builder.addExpression(
        CodeExpression(
          Code('_${_generateFieldName(
            p.parameter.type,
            tag?._toAssignTag(),
          )} = ${p.parameter.name}; return this'),
        ),
      );
    });
  }

  /// Returns the method body named 'build' of the component builder.
  Code _buildComponentBuilderBuildMethodBody(
    j.ComponentBuilder componentBuilder,
    DartType componentType,
  ) {
    return Block((BlockBuilder builder) {
      final Iterable<Expression> parameters = componentBuilder.parameters
          .map((j.ComponentBuilderParameter parameter) {
        final Tag? tag =
            parameter.parameter.enclosingElement!.getQualifierTag();
        final CodeExpression codeExpression = CodeExpression(
          Code('_${_generateFieldName(
            parameter.parameter._tryGetType(),
            tag?._toAssignTag(),
          )}!'),
        );
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

      for (final Code value in assertCodes) {
        builder.addExpression(CodeExpression(value));
      }

      final Expression newInstance =
          refer('${_createComponentName(componentType.getName())}._create')
              .newInstance(parameters);

      builder.addExpression(
        CodeExpression(
          Block.of(
            <Code>[
              const Code('return '),
              newInstance.code,
            ],
          ),
        ),
      );
    });
  }

  /// Returns the name for the generated component class.
  /// [name] The name of the component for which you want to generate a name.
  /// Usually the class name.
  ///
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

  /// Returns a list of graph objects for which the provider field should be
  /// generated. If the current component is a graph object, it does not need to
  /// be generated. In this case, the call will be like 'this'.
  Iterable<GraphObject> _filterDependenciesForFields(
      List<GraphObject> dependencies) {
    return dependencies.where((GraphObject dependency) {
      final ClassElement typeElement = dependency.type.element as ClassElement;
      final bool isCurrentComponent =
          getComponentAnnotation(typeElement) != null &&
              dependency.type == _componentType;
      return !isCurrentComponent;
    });
  }

  /// Returns a list of all providers that are used in the current component.
  /// Example of field:
  /// ```
  /// late final _i2.IProvider<int> _intProvider =
  ///      _i2.Provider<int>(() => _i1.Module2.providerInt());
  /// ```
  List<Field> _buildProvidesFields() {
    final List<Field> fields = <Field>[];

    final Iterable<GraphObject> filteredDependencies =
        _filterDependenciesForFields(_componentContext.objectsGraph);

    for (final GraphObject graphObject in filteredDependencies) {
      check(
        !graphObject.type.isProvider,
        () => providerNotAllowed(graphObject.type),
      );

      final ProviderSource? provider =
          _componentContext.findProvider(graphObject.type, graphObject.tag);

      // Do not generate code if method of component annotated with qualifier,
      // but constructor of class is injected
      if (provider == null && graphObject.tag != null) {
        throw JuggerError(
          buildProviderNotFoundMessage(graphObject.type, graphObject.tag),
        );
      }

      if (provider is! ArgumentSource && provider is! AnotherComponentSource) {
        fields.add(Field((FieldBuilder b) {
          final Tag? tag = graphObject.tag;
          b.name = '_${_generateFieldName(
            graphObject.type,
            tag?._toAssignTag(),
          )}Provider';

          final String generic = _allocator.allocate(
            refer(_allocateDependencyTypeName(graphObject)),
          );
          b.late = true;
          b.modifier = FieldModifier.final$;

          final ProviderSource? provider =
              _componentContext.findProvider(graphObject.type, tag);

          if (provider is ModuleSource) {
            b.assignment = _buildProviderFromMethod(
              provider.method.element,
            );
          } else {
            final ClassElement typeElement =
                graphObject.type.element as ClassElement;

            check(
              !(isCore(typeElement) || typeElement.isAbstract),
              () => buildProviderNotFoundMessage(graphObject.type, tag),
            );
            b.assignment = _buildProviderFromType(graphObject.type);
          }

          b.type =
              Reference('IProvider<$generic>', 'package:jugger/jugger.dart');
        }));
      }
    }

    // Sort so that the sequence is preserved with each code generation (for
    // test stability)
    return fields..sort((Field a, Field b) => a.name.compareTo(b.name));
  }

  /// A helper function that allocates the given type of object graph and
  /// returns its name. If the type is generic, nested types in brackets will
  /// also be allocated.
  String _allocateDependencyTypeName(GraphObject dependency) {
    return _allocateTypeName(dependency.type);
  }

  /// A helper function that allocates the given type and returns its name.
  /// If the type is generic, nested types in brackets will also be allocated.
  /// Example of result:
  /// ```
  /// List<_i1.Item>
  /// _i1.Item
  /// ```
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

  List<Method> _buildProvideProperties() {
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

  /// Returns a list of component methods, their implementation, each method
  /// calls the corresponding type provider.
  /// Example of result:
  /// ```
  /// @override
  /// _i1.Config getName() => _configProvider.get();
  /// ```
  List<Method> _buildProvideMethods() {
    final List<MethodElement> methods =
        _componentContext.component.provideMethods;
    final List<Method> newProperties = <Method>[];

    for (final MethodElement method in methods) {
      _log(
          'build provide method for: ${method.enclosingElement.name}.${method.name}');
      final Method m = Method((MethodBuilder b) {
        b.annotations.add(_overrideAnnotationExpression);
        b.name = method.name;
        b.returns = refer(_allocateTypeName(method.returnType));

        b.lambda = true;
        b.body = Code(
          _generateAssignString(
            method.returnType,
            method.getQualifierTag(),
          ),
        );
      });
      newProperties.add(m);
    }

    // Sort so that the sequence is preserved with each code generation (for
    // test stability)
    return newProperties
      ..sort((Method a, Method b) => a.name!.compareTo(b.name!));
  }

  /// Returns a list of component properties, their implementation, each
  /// property calls the corresponding type provider.
  /// ```
  /// @override
  /// String get string => _stringProvider.get();
  /// ```
  List<Method> _buildMembersInjectorMethods(
    List<j.MemberInjectorMethod> fields,
    ClassBuilder classBuilder,
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

      final List<j.InjectedMember> members = memberElement.getInjectedMembers();

      builder.body = Block((BlockBuilder b) {
        for (final j.InjectedMember member in members.toSet()) {
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

  /// Returns a assign of type as string, which can be used in the [Code].
  /// If the component does not have a source for the type, an error will be
  /// thrown.
  ///
  /// Returns a field call on the component. A field can be a provider of this
  /// component, a call to another component, or a component argument.
  ///
  /// [tag] is used as class field prefix if exists.
  /// [callGet] is used to optionally call a .get() on a provider.
  ///
  /// Example of result:
  /// ```
  /// _myRepositoryProvider.get()
  /// ```
  /// or
  /// ```
  /// _myRepositoryProvider
  /// ```
  /// if callGet passed as false.
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
        () => buildProviderNotFoundMessage(depType, tag),
      );
      return _generateAssignString(
        provider!.type,
        provider.tag,
        false,
      );
    }

    final ProviderSource? provider = _componentContext.findProvider(type, tag);

    if (provider is ArgumentSource) {
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

    final List<ConstructorElement> injectedConstructors =
        type.element!.getInjectedConstructors();

    if (injectedConstructors.isEmpty) {
      final j.Method? provideMethod =
          _componentContext.findProvideMethod(type: type, tag: tag);
      check(
        provideMethod != null,
        () => buildProviderNotFoundMessage(type, tag),
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

    return uncapitalize(typeName);
  }

  /// Returns a method that is called immediately after the component is
  /// initialized. The method calls the provider's .get() method to initialize
  /// graph objects.
  Method _buildInitNonLazyMethod() {
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
        // Sort so that the sequence is preserved with each code generation (for
        // test stability)
        ..sort((ProviderSource a, ProviderSource b) =>
            a.type.getName().compareTo(b.type.getName()));

      for (final ProviderSource source in nonLazyProviders) {
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

  /// Returns true if there are non-lazy graph objects in the component. The
  /// source in the module must be annotated with @nonLazy.
  bool hasNonLazyProviders() {
    return _componentContext.providerSources.any((ProviderSource source) =>
        source.annotations.any(
            (j.Annotation annotation) => annotation is j.NonLazyAnnotation));
  }

  // region provider

  /// Build provider from given type. Use source for construct assign code of
  /// provider.
  /// Example of result:
  /// ```
  /// SingletonProvider<MyProvider>(() => AppModule.provideMyProvider());
  /// ```
  Code _buildProviderFromType(DartType type) {
    type.checkUnsupportedType();
    final ConstructorElement injectedConstructor =
        type.getRequiredInjectedConstructor();

    final Expression newInstance =
        _getProviderReferenceOfElement(injectedConstructor)
            .newInstance(<Expression>[
      _buildExpressionBody(
        _buildCallConstructor(injectedConstructor),
      ),
    ]);

    return newInstance.code;
  }

  /// Build provider from given method.
  /// Example of result:
  /// ```
  /// SingletonProvider<MyProvider>(() => AppModule.provideMyProvider());
  /// ```
  Code _buildProviderFromMethod(MethodElement method) {
    _log(
      'build provider from method: ${method.toNameWithPath()}',
    );
    if (method.isStatic) {
      return _buildProviderFromStaticMethod(method);
    } else if (method.isAbstract) {
      return _buildProviderFromAbstractMethod(method);
    } else {
      throw JuggerError(
        'provided method must be abstract or static [${method.enclosingElement.name}.${method.name}]',
      );
    }
  }

  /// Build provider from given method with given source. Use source for
  /// construct assign code of provider.
  /// Example of result:
  /// ```
  /// SingletonProvider<MyProvider>(() => AppModule.provideMyProvider());
  /// ```
  Code _buildProvider(MethodElement method, ProviderSource source) {
    final Expression newInstance =
        _getProviderReferenceOfElement(method).newInstance(
      <Expression>[
        _buildExpressionBody(
          Code(
            _generateAssignString(
              source.type,
              source.tag,
            ),
          ),
        ),
      ],
    );

    return newInstance.code;
  }

  /// Build provider from given method. Method must have only 'bind' type.
  /// Example of result:
  /// ```
  /// SingletonProvider<MyProvider>(() => AppModule.provideMyProvider());
  /// ```
  Code _buildProviderFromAbstractMethod(MethodElement method) {
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

    final ProviderSource? provider =
        _componentContext.findProvider(parameter.thisType);

    if (provider is AnotherComponentSource) {
      return _buildProvider(method, provider);
    } else if (provider is ModuleSource) {
      return _buildProvider(method, provider);
    }

    // if injected constructor is missing it makes no sense to do anything.
    final ConstructorElement injectedConstructor =
        parameter.thisType.getRequiredInjectedConstructor();

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
          _buildExpressionBody(
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
      _buildExpressionBody(
        _buildCallConstructor(injectedConstructor),
      ),
    ]);

    return newInstance.code;
  }

  // endregion provider

  /// Build expression body with given body of code.
  /// Example of result:
  /// ```
  /// () => print('hello')
  /// ```
  Expression _buildExpressionBody(Code body) {
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

  /// Build provider from given static method.
  /// Example of result:
  /// ```
  /// SingletonProvider<MyProvider>(() => AppModule.provideMyProvider());
  /// ```
  Code _buildProviderFromStaticMethod(MethodElement method) {
    _log(
        'build provider from static method: ${method.enclosingElement.name}.${method.name}');

    check(
      method.returnType.element is ClassElement,
      () => '${method.returnType.element} not supported.',
    );
    final Element moduleClass = method.enclosingElement;
    final Expression newInstance =
        _getProviderReferenceOfElement(method).newInstance(<Expression>[
      _buildExpressionBody(
        Block.of(
          <Code>[
            refer(moduleClass.name!, createElementPath(moduleClass)).code,
            const Code('.'),
            _buildCallMethod(method)
          ],
        ),
      )
    ]);

    return newInstance.code;
  }

  /// Returns the code that calls the given constructor. Calls injected methods
  /// if needed.
  /// Example of result:
  /// ```
  /// MyClass();
  /// ```
  Code _buildCallConstructor(ConstructorElement constructor) {
    final ProviderSource? provider =
        _componentContext.findProvider(constructor.type);

    if (provider is ModuleSource) {
      return Code(
        _generateAssignString(
          provider.type,
          provider.tag,
        ),
      );
    }
    final ClassElement classElement = constructor.enclosingElement;
    final Reference reference =
        refer(classElement.name, createElementPath(classElement));

    if (constructor.parameters.isEmpty) {
      late final Expression instanceExpression;
      if (constructor.isConst && constructor.parameters.isEmpty) {
        instanceExpression = reference.constInstance(<Expression>[]);
      } else {
        instanceExpression = reference.newInstance(<Expression>[]);
      }
      return _callInjectedMethodsIfNeeded(instanceExpression, classElement)
          .code;
    }

    final Expression newInstanceExpression = _buildCallArgumentsExpression(
      constructor.parameters,
      reference,
    );
    return _callInjectedMethodsIfNeeded(
      newInstanceExpression,
      classElement,
    ).code;
  }

  /// Returns the code that calls the given method. Method can be: module
  /// method, method of another component.
  /// Example of result:
  /// ```
  /// provideMyProvider();
  /// ```
  Code _buildCallMethod(MethodElement method) {
    final Reference reference = refer(method.name);
    if (method.parameters.isEmpty) {
      return reference.newInstance(<Expression>[]).code;
    }

    return _buildCallArgumentsExpression(
      method.parameters,
      reference,
    ).code;
  }

  /// Returns a call to the arguments usually of a method or constructor. Only
  /// named or only positional arguments are supported.
  /// [parameters] to be called.
  /// [reference] reference to a method or constructor.
  /// Example of result:
  /// ```
  /// provideMyClass(arg1, args2); // for method
  /// MyClass(arg1, args2); // for constructor
  /// ```
  Expression _buildCallArgumentsExpression(
    List<ParameterElement> parameters,
    Reference reference,
  ) {
    final bool isPositional =
        parameters.any((ParameterElement p) => p.isPositional);
    final bool isNamed = parameters.any((ParameterElement p) => p.isNamed);

    check(
      !(isPositional && isNamed),
      () => buildErrorMessage(
        error: JuggerErrorId.invalid_parameters_types,
        message:
            '${reference.symbol} can have only positional parameters or only named parameters.',
      ),
    );

    if (isPositional) {
      return reference.newInstance(
        _buildArgumentsExpressions(parameters).values.toList(),
      );
    }

    if (isNamed) {
      final Expression newInstance = reference.newInstance(
        <Expression>[],
        _buildArgumentsExpressions(parameters),
      );
      return newInstance;
    }

    throw JuggerError('Unable to call constructor or method.');
  }

  /// Returns a call of injected methods sequentially, starting with the base
  /// class. Will be called if the element is a class.
  /// Example of result:
  /// ```
  /// ..initSuperBase(_intProvider.get())
  /// ..initBase(_intProvider.get())
  /// ..init(_intProvider.get()));
  /// ```
  Expression _callInjectedMethodsIfNeeded(
    Expression initialExpression,
    Element element,
  ) {
    if (element is ClassElement) {
      final Set<MethodElement> methods = element.getInjectedMethods();
      if (methods.isNotEmpty) {
        final List<Code> methodsCalls = methods.expand((MethodElement method) {
          return <Code>[
            const Code('..'),
            _buildCallMethod(method),
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

  Map<String, Expression> _buildArgumentsExpressions(
    List<ParameterElement> parameters,
  ) {
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
