import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';

import '../builder/global_config.dart';
import '../errors_glossary.dart';
import '../jugger_error.dart';
import '../utils/dart_type_ext.dart';
import '../utils/element_annotation_ext.dart';
import '../utils/element_ext.dart';
import '../utils/list_ext.dart';
import '../utils/source_ext.dart';
import '../utils/tag_ext.dart';
import '../utils/utils.dart';
import 'asset_context.dart';
import 'component_context.dart';
import 'component_result.dart';
import 'disposable_manager.dart';
import 'multibindings/multibindings_group.dart';
import 'multibindings/multibindings_info.dart';
import 'tag.dart';
import 'type_name_registry.dart';
import 'unique_name_registry.dart';
import 'visitors.dart';
import 'wrappers.dart' as j;
import 'wrappers.dart';

/// Delegate to generate the jugger components within one asset.
class ComponentBuilderDelegate {
  ComponentBuilderDelegate({
    required AssetContext assetContext,
  }) : _assetContext = assetContext;

  static const String _jugger = 'package:jugger/jugger.dart';

  static const Expression _overrideAnnotationExpression = Reference('override');

  final AssetContext _assetContext;

  late ComponentContext _componentContext;
  late DisposablesManager _disposablesManager;
  late DartType _componentType;

  late final String _thisComponentName =
      _createComponentName(_componentContext.component.element.name);

  GlobalConfig get globalConfig => _assetContext.globalConfig;

  Allocator get _allocator => _assetContext.allocator;

  TypeNameGenerator get _typeNameGenerator => _assetContext.typeNameGenerator;

  UniqueIdGenerator get _uniqueIdGenerator => _assetContext.uniqueIdGenerator;

  ComponentResult generateComponent({
    required Component component,
  }) {
    _componentType = component.element.thisType;
    _componentContext = ComponentContext(
      component: component,
      componentBuilder: component.resolveComponentBuilder() ??
          // for compatibility, will be removed in future release
          _assetContext.getComponentBuilderOf(
            component.element.thisType,
          ),
    );
    _disposablesManager = DisposablesManager(_componentContext);

    final bool hasDisposables = _disposablesManager.hasDisposables();
    final Class componentClass = _createComponentClass();

    final List<Class> multibindingsProviderClasses = _componentContext
        .multibindingsManager
        .getBindingsInfo()
        .map(_buildMultibindingsProviderClass)
        .sortedBy((Class c) => c.name);

    final j.ComponentBuilder? componentBuilder =
        _componentContext.componentBuilder;

    return ComponentResult(
      componentClass: componentClass,
      multibindingsProviderClasses: multibindingsProviderClasses,
      hasDisposables: hasDisposables,
      componentBuilder: componentBuilder != null
          ? _buildComponentBuilderClass(componentBuilder)
          : null,
    );
  }

  Class _createComponentClass() {
    final bool hasDisposables = _disposablesManager.hasDisposables();
    final j.Component component = _componentContext.component;
    return Class((ClassBuilder classBuilder) {
      if (hasDisposables) {
        check(
          component.disposeMethod != null,
          () => buildErrorMessage(
            error: JuggerErrorId.missing_dispose_method,
            message:
                'Missing dispose method of component ${component.element.name}.',
          ),
        );
      } else {
        check(
          component.disposeMethod == null,
          () => buildErrorMessage(
            error: JuggerErrorId.missing_disposables,
            message: 'The component ${component.element.name} does not contain '
                'disposable objects, but the dispose method '
                '${component.disposeMethod?.element.enclosingElement.name}.'
                '${component.disposeMethod?.element.name} is declared.',
          ),
        );
      }

      classBuilder
        ..fields.addAll(_buildProvidesFields())
        ..fields.addAll(
          _buildConstructorFields(_componentContext.componentBuilder),
        )
        ..methods.addAll(
          _buildComponentMembers(
            _componentContext.component.methodsAccessors
                .map((j.MethodObjectAccessor e) => e.method),
          ),
        )
        ..methods.addAll(
          _buildComponentMembers(
            _componentContext.component.propertiesAccessors
                .map((j.PropertyObjectAccessor e) => e.property),
          ),
        )
        ..methods.addAll(
          _buildMembersInjectorMethods(
            component.memberInjectors,
            classBuilder,
          ),
        )
        ..implements.add(
          Reference(
            component.element.name,
            createElementPath(_assetContext.lib),
          ),
        )
        ..constructors.add(
          _buildConstructor(_componentContext.componentBuilder),
        )
        ..name = _thisComponentName;

      if (hasDisposables) {
        classBuilder
          ..fields.add(_buildDisposableManagerField())
          ..methods.add(_buildDisposeMethod());
      }

      if (_disposablesManager.disposableArguments.isNotEmpty) {
        classBuilder.methods.add(_buildRegisterDisposableArgumentsMethod());
      }

      if (_hasNonLazyProviders()) {
        classBuilder.methods.add(_buildInitNonLazyMethod());
      }
    });
  }

  /// Returns a class of component builder.
  Class _buildComponentBuilderClass(
    j.ComponentBuilder componentBuilder,
  ) {
    return Class((ClassBuilder classBuilder) {
      classBuilder.name = '${_thisComponentName}Builder';

      classBuilder.implements.add(
        refer(
          componentBuilder.element.name,
          createElementPath(componentBuilder.element),
        ),
      );
      classBuilder.methods.addAll(
        componentBuilder.methods.map(
          (MethodElement m) {
            return _buildComponentBuilderMethod(componentBuilder, m);
          },
        ),
      );
      classBuilder.fields.addAll(
        componentBuilder.parameters.map(_buildComponentParameter),
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
        type: parameter.parameter.type,
        tag: tag?.toAssignTag(),
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
        refer(
          '_${_generateFieldName(
            type: p.parameter.type,
            tag: tag?.toAssignTag(),
          )}',
        ).assign(refer(p.parameter.name)),
      );
      builder.addExpression(const CodeExpression(Code('return this')));
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
        return refer(
          '_${_generateFieldName(
            type: parameter.parameter.tryGetType(),
            tag: tag?.toAssignTag(),
          )}',
        ).nullChecked;
      });

      final List<Code> assertCodes = componentBuilder.parameters
          .map((j.ComponentBuilderParameter parameter) {
        final Tag? tag =
            parameter.parameter.enclosingElement!.getQualifierTag();
        final StringBuffer code = StringBuffer()
          ..write('assert(_')
          ..write(
            _generateFieldName(
              type: parameter.parameter.type,
              tag: tag?.toAssignTag(),
            ),
          )
          ..write(' != null) ');
        return Code(code.toString());
      }).toList();

      for (final Code value in assertCodes) {
        builder.addExpression(CodeExpression(value));
      }

      final Expression call =
          refer('$_thisComponentName._create').call(parameters);

      builder.addExpression(
        CodeExpression(
          Block.of(
            <Code>[
              const Code('return '),
              call.code,
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

  /// Returns a list of all providers that are used in the current component.
  /// Example of field:
  /// ```
  /// late final _i2.IProvider<int> _intProvider =
  ///      _i2.Provider<int>(() => _i1.Module2.providerInt());
  /// ```
  List<Field> _buildProvidesFields() {
    final List<Field> fields = <Field>[];

    final Iterable<GraphObject> filteredDependencies =
        _componentContext.graphObjects.where(
      (GraphObject graphObject) {
        return graphObject.multibindingsInfo == null;
      },
    ).where((GraphObject graphObject) {
      final ProviderSource source = _componentContext.findProvider(
        graphObject.type,
        graphObject.tag,
        graphObject.multibindingsInfo,
      );
      // just 'this' for assign expression, field is not needed
      return source is! ThisComponentSource;
    });

    for (final GraphObject graphObject in filteredDependencies) {
      checkUnexpected(
        !graphObject.type.isValueProvider,
        () => buildUnexpectedErrorMessage(
          message:
              'found registered dependency of provider [${graphObject.type.getName()}]',
        ),
      );

      final ProviderSource provider = _componentContext.findProvider(
        graphObject.type,
        graphObject.tag,
        graphObject.multibindingsInfo,
      );

      if (provider is! ArgumentSource && provider is! AnotherComponentSource) {
        fields.add(
          Field((FieldBuilder b) {
            final Tag? tag = graphObject.tag;

            b.name = '_${_createMultibindingsProviderFieldName(
              type: graphObject.type,
              tag: graphObject.tag,
              multibindingsInfo: graphObject.multibindingsInfo,
            )}';

            final String generic = _allocator.allocate(
              refer(_allocateDependencyTypeName(graphObject)),
            );
            b.late = true;
            b.modifier = FieldModifier.final$;

            final ProviderSource provider = _componentContext.findProvider(
              graphObject.type,
              tag,
              graphObject.multibindingsInfo,
            );

            if (provider is ModuleSource) {
              b.assignment =
                  _buildProviderFromMethod(provider.method, null).code;
            } else if (provider is InjectedConstructorSource) {
              b.assignment =
                  _buildProviderFromConstructor(provider.element).code;
            } else if (provider is MultibindingsSource) {
              final Iterable<GraphObject> collectedObjects =
                  _collectMultibindingsObjects(provider.multibindingsGroup);

              final bool hasDependencies = collectedObjects
                  .any((GraphObject object) => object.dependencies.isNotEmpty);

              final Code assignment = Block.of(
                <Code>[
                  Code(
                    '_${_createMultibindingsProviderClassName(
                      type: graphObject.type,
                      tag: graphObject.tag,
                      multibindingsInfo: graphObject.multibindingsInfo,
                    )}',
                  ),
                  if (hasDependencies)
                    const Code('(this)')
                  else
                    const Code('()')
                ],
              );

              b.assignment = assignment;
            } else {
              throw JuggerError(
                buildUnexpectedErrorMessage(
                  message: 'Unexpected provider $provider',
                ),
              );
            }

            b.type = refer('IProvider<$generic>', _jugger);
          }),
        );
      }
    }

    // Sort so that the sequence is preserved with each code generation (for
    // test stability)
    return fields.sortedBy((Field field) => field.name);
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
    checkUnexpected(
      t is InterfaceType,
      () => buildUnexpectedErrorMessage(message: 'type [$t] not supported'),
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

    final StringBuffer typeNameBuilder = StringBuffer()
      ..write(name)
      ..write('<')
      ..write(
        type.typeArguments.map((DartType type) {
          type.checkUnsupportedType();
          return _allocateTypeName(type as InterfaceType);
        }).join(','),
      )
      ..write('>');
    return typeNameBuilder.toString();
  }

  /// Returns a list of component members or properties, their implementation,
  /// each member calls the corresponding type provider.
  /// Example of result:
  /// ```
  /// @override
  /// _i1.Config getName() => _configProvider.get();
  /// _i1.Config get name => _configProvider.get();
  /// ```
  /// [items] must be list of properties or method.
  List<Method> _buildComponentMembers(Iterable<ExecutableElement> items) {
    final List<Method> newMembers = <Method>[];

    for (final ExecutableElement executable in items) {
      checkUnexpected(
        executable is PropertyAccessorElement || executable is MethodElement,
        () => 'executable $executable not supported.',
      );
      final Method m = Method((MethodBuilder b) {
        b.annotations.add(_overrideAnnotationExpression);
        b.name = executable.name;
        b.returns = refer(_allocateTypeName(executable.returnType));

        final Expression assignReference = _generateAssignExpression(
          type: executable.returnType,
          tag: executable.getQualifierTag(),
        );
        if (_disposablesManager.hasDisposables()) {
          b.body = Block.of(
            <Code>[
              _buildCheckDisposed(),
              assignReference.returned.statement,
            ],
          );
        } else {
          b.body = assignReference.code;
        }
        if (executable is PropertyAccessorElement) {
          b.type = MethodType.getter;
        }
      });
      newMembers.add(m);
    }

    // Sort so that the sequence is preserved with each code generation (for
    // test stability)
    return newMembers.sortedBy((Method method) => method.name!);
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

      final ParameterElement parameterElement = method.element.parameters[0];

      final ClassElement memberElement =
          parameterElement.type.element! as ClassElement;
      builder.requiredParameters.add(
        Parameter((ParameterBuilder b) {
          b.name = uncapitalize(parameterElement.name);
          b.type = Reference(
            parameterElement.type.getName(),
            createElementPath(parameterElement.type.element!),
          );
        }),
      );

      final List<j.InjectedMember> members = memberElement.getInjectedMembers();

      builder.body = Block((BlockBuilder b) {
        for (final j.InjectedMember member in members.toSet()) {
          final Tag? tag = member.element.getQualifierTag();
          b.addExpression(
            refer(parameterElement.name).property(member.element.name).assign(
                  _generateAssignExpression(
                    type: member.element.type,
                    tag: tag,
                  ),
                ),
          );
        }

        if (memberElement.getInjectedMethods().isNotEmpty) {
          b.addExpression(
            _callInjectedMethodsIfNeeded(
              refer(parameterElement.name),
              memberElement,
            ),
          );
        }
      });

      return builder.build();
    }).toList();
  }

  /// Returns a assign of type as expression, which can be used as code.
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
  Expression _generateAssignExpression({
    required DartType type,
    Tag? tag,
    bool callGet = true,
    String? prefixScope,
  }) {
    type.checkUnsupportedType();

    if (type == _componentType) {
      if (prefixScope != null) {
        return refer(prefixScope);
      }
      return const Reference('this');
    }

    if (type.isValueProvider) {
      final DartType depType = type.getSingleTypeArgument;
      final ProviderSource provider =
          _componentContext.findProvider(depType, tag);
      return CodeExpression(
        Block.of(
          <Code>[
            _generateAssignExpression(
              type: provider.type,
              tag: provider.tag,
              callGet: false,
            ).code,
            if (type.isLazyType) const Code('.toLazy()'),
          ],
        ),
      );
    }

    final ProviderSource provider = _componentContext.findProvider(type, tag);

    if (provider is ArgumentSource) {
      String? finalSting;

      if (tag != null) {
        finalSting = generateMd5(tag.uniqueId);
      }

      final StringBuffer assignExpressionBuilder = StringBuffer();
      if (prefixScope != null) {
        assignExpressionBuilder
          ..write(prefixScope)
          ..write('.');
      }
      assignExpressionBuilder
        ..write('_')
        ..write(_generateFieldName(type: type, tag: finalSting));

      return refer(assignExpressionBuilder.toString());
    }

    if (provider is AnotherComponentSource) {
      final StringBuffer assignExpressionBuilder = StringBuffer();
      if (prefixScope != null) {
        assignExpressionBuilder
          ..write(prefixScope)
          ..write('.');
      }
      assignExpressionBuilder.write(provider.assignString);
      return refer(assignExpressionBuilder.toString());
    }

    return _generateProviderCall(
      tag: tag,
      type: type,
      callGet: callGet,
      prefixScope: prefixScope,
    );
  }

  /// Returns a provider call as expression, which can be used as code.
  /// It is assumed that the provider exists as a field of the component.
  /// [tag] is used as class field prefix if exists.
  /// [callGet] is used to optionally call a .get() on a provider.
  Expression _generateProviderCall({
    required Tag? tag,
    required DartType type,
    required bool callGet,
    required String? prefixScope,
  }) {
    final String? finalTag;

    if (tag == null) {
      finalTag = null;
    } else {
      finalTag = generateMd5(tag.uniqueId);
    }

    final StringBuffer finalExpressionBuilder = StringBuffer();
    if (prefixScope != null) {
      finalExpressionBuilder.write('$prefixScope.');
    }
    finalExpressionBuilder
      ..write('_')
      ..write(_generateFieldName(type: type, tag: finalTag))
      ..write('Provider');

    Expression finalExpression = refer(finalExpressionBuilder.toString());
    if (callGet) {
      finalExpression = finalExpression.property('get').call(<Expression>[]);
    }
    return finalExpression;
  }

  /// Generate field name of given type. Uses the tag if it exists. Usually
  /// generates a name for a class field.
  /// If the type has invalid characters, such as brackets, they will be
  /// stripped.
  String _generateFieldName({
    required DartType type,
    required String? tag,
  }) {
    final String typeName = _typeNameGenerator.generate(type);
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
          .where(
            (ProviderSource source) =>
                source.annotations.anyInstance<j.NonLazyAnnotation>(),
          )
          .toList()
          // Sort so that the sequence is preserved with each code generation (for
          // test stability)
          .sortedBy((ModuleSource source) => source.type.getName());

      for (final ProviderSource source in nonLazyProviders) {
        check(
          source.isScoped,
          () => buildErrorMessage(
            error: JuggerErrorId.unscoped_non_lazy,
            message: 'It makes no sense to initialize a non-scoped object:\n'
                '${source.sourceString}',
          ),
        );

        builder.statements.add(
          _generateAssignExpression(
            type: source.type,
            tag: source.tag,
          ).statement,
        );
      }
    });

    return builder.build();
  }

  /// Returns true if there are non-lazy graph objects in the component. The
  /// source in the module must be annotated with @nonLazy.
  bool _hasNonLazyProviders() {
    return _componentContext.providerSources.any(
      (ProviderSource source) =>
          source.annotations.anyInstance<j.NonLazyAnnotation>(),
    );
  }

  // region provider

  /// Build provider from given constructor.
  /// Example of result:
  /// ```
  /// SingletonProvider<MyClass>(() => MyClass());
  /// ```
  Expression _buildProviderFromConstructor(ConstructorElement constructor) {
    final Expression callExpression =
        _getProviderReferenceOfElement(constructor).newInstance(
      <Expression>[
        _buildBodyWithRegisterDisposableOfType(
          type: constructor.enclosingElement.thisType,
          returnBlock: _buildCallConstructor(constructor),
        )
      ],
    );

    return callExpression;
  }

  /// Build provider from given method.
  /// Example of result:
  /// ```
  /// SingletonProvider<MyClass>(() => AppModule.provideMyClass());
  /// ```
  Expression _buildProviderFromMethod(
    j.ProvideMethod method,
    String? prefixScope,
  ) {
    if (method is j.StaticProvideMethod) {
      return _buildProviderFromStaticMethod(method, prefixScope);
    } else if (method is j.AbstractProvideMethod) {
      return _buildProviderFromAbstractMethod(method, prefixScope);
    } else {
      throw UnexpectedJuggerError(
        'Unsupported method [${method.element.enclosingElement.name}.'
        '${method.element.name}]',
      );
    }
  }

  /// Build provider from given method with given source. Use source for
  /// construct assign code of provider or another component.
  /// Example of result:
  /// ```
  /// SingletonProvider<MyClass>(() => _appComponent.getMyClass());
  /// ```
  Expression _buildProvider(MethodElement method, ProviderSource source) {
    final Expression callExpression =
        _getProviderReferenceOfElement(method).call(
      <Expression>[
        _buildExpressionClosure(
          _generateAssignExpression(
            type: source.type,
            tag: source.tag,
          ).code,
        ),
      ],
    );

    return callExpression;
  }

  /// Build provider from given method. Method must have only 'bind' type.
  /// Example of result:
  /// ```
  /// SingletonProvider<MyClass>(() => _myClassProvider.get());
  /// ```
  Expression _buildProviderFromAbstractMethod(
    j.AbstractProvideMethod method,
    String? prefixScope,
  ) {
    final ProviderSource provider =
        _componentContext.findProvider(method.assignableType);

    if (provider is AnotherComponentSource) {
      return _buildProvider(method.element, provider);
    } else if (provider is ModuleSource) {
      return _buildProvider(method.element, provider);
    }

    checkUnexpected(
      provider is InjectedConstructorSource,
      () {
        return 'Expected InjectedConstructorSource, but was $provider.';
      },
    );

    if (method.element.getBindAnnotationOrNull() != null) {
      final Expression callExpression = _getProviderReferenceOfElement(
        method.element,
      ).call(
        <Expression>[
          _buildExpressionClosure(
            _generateAssignExpression(
              type: method.assignableType,
              prefixScope: prefixScope,
            ).code,
          ),
        ],
      );
      return callExpression;
    }

    throw UnexpectedJuggerError(
      'Unknown provided type of method '
      '${method.element.getDisplayString(withNullability: false)}',
    );
  }

  // endregion provider

  /// Build expression closure with given body of code.
  /// Example of result:
  /// ```
  /// () => print('hello')
  /// ```
  Expression _buildExpressionClosure(Code body) {
    return Method(
      (MethodBuilder b) => b
        ..body = body
        ..lambda = true,
    ).closure;
  }

  /// Build provider from given static method.
  /// Example of result:
  /// ```
  /// SingletonProvider<MyClass>(() => AppModule.provideMyClass());
  /// ```
  Expression _buildProviderFromStaticMethod(
    j.StaticProvideMethod method,
    String? prefixScope,
  ) {
    final Element moduleClass = method.element.enclosingElement;
    final Expression callExpression =
        _getProviderReferenceOfElement(method.element).newInstance(<Expression>[
      _buildBodyWithRegisterDisposable(
        method: method,
        returnBlock: Block.of(
          <Code>[
            refer(moduleClass.name!, createElementPath(moduleClass)).code,
            const Code('.'),
            _buildCallMethod(method.element, prefixScope).code,
          ],
        ),
      )
    ]);

    return callExpression;
  }

  /// Returns the code that calls the given constructor. Calls injected methods
  /// if needed.
  /// Example of result:
  /// ```
  /// MyClass();
  /// ```
  Code _buildCallConstructor(ConstructorElement constructor) {
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
      null,
    );
    return _callInjectedMethodsIfNeeded(
      newInstanceExpression,
      classElement,
    ).code;
  }

  /// Returns the expression that calls the given method. Method can be: module
  /// method, method of another component.
  /// Example of result:
  /// ```
  /// provideMyClass();
  /// ```
  Expression _buildCallMethod(
    MethodElement method,
    String? prefixScope,
  ) {
    final Reference reference = refer(method.name);
    if (method.parameters.isEmpty) {
      return reference.call(<Expression>[]);
    }

    return _buildCallArgumentsExpression(
      method.parameters,
      reference,
      prefixScope,
    );
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
    String? prefixScope,
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
        _buildArgumentsExpressions(parameters, prefixScope).values.toList(),
      );
    }

    if (isNamed) {
      final Expression newInstance = reference.newInstance(
        <Expression>[],
        _buildArgumentsExpressions(parameters, prefixScope),
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
            _buildCallMethod(method, null).code,
          ];
        }).toList();
        final Block block = Block.of(
          <Code>[
            initialExpression.code,
            ...methodsCalls,
          ],
        );
        return CodeExpression(block);
      }
    }

    return initialExpression;
  }

  /// Returns a provider reference that returns the type that is associated with
  /// the element.
  /// Only certain element types are supported, otherwise throws an error.
  Reference _getProviderReferenceOfElement(Element element) {
    checkUnexpected(
      element is MethodElement || element is ConstructorElement,
      () => buildUnexpectedErrorMessage(message: '$element not supported'),
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
      _jugger,
    );
  }

  /// Returns the string class type of the given element and allocates it.
  /// Only certain element types are supported, otherwise throws an error.
  String _getClassTypeAsString(Element element) {
    if (element is ConstructorElement) {
      final ClassElement c = element.enclosingElement;
      return _allocator.allocate(
        Reference(c.thisType.getName(), c.librarySource.uri.toString()),
      );
    } else if (element is MethodElement) {
      return _allocator.allocate(refer(_allocateTypeName(element.returnType)));
    }
    throw JuggerError(
      'unsupported type: ${element.name}, ${element.runtimeType}',
    );
  }

  /// Build constructor for this component. If the component has a builder, it
  /// will be private, because depending on whether it has one or not, the
  /// creation of the component is different.
  Constructor _buildConstructor(j.ComponentBuilder? componentBuilder) {
    return Constructor((ConstructorBuilder constructorBuilder) {
      if (_hasNonLazyProviders()) {
        constructorBuilder.body = const Code('_initNonLazy();');
      }

      if (componentBuilder == null) {
        constructorBuilder.name = 'create';
      } else {
        constructorBuilder.name = '_create';
        constructorBuilder.requiredParameters.addAll(
          componentBuilder.parameters
              .map((j.ComponentBuilderParameter parameter) {
            return Parameter((ParameterBuilder b) {
              b.toThis = true;
              final Tag? tag =
                  parameter.parameter.enclosingElement!.getQualifierTag();
              b.name = '_${_generateFieldName(
                type: parameter.parameter.type,
                tag: tag?.toAssignTag(),
              )}';
            });
          }),
        );
      }

      if (_disposablesManager.disposableArguments.isNotEmpty) {
        constructorBuilder.body = const Code('_registerDisposableArguments();');
      }
    });
  }

  /// Returns a list of fields for the constructor. fields correspond to fields
  /// from component builder.
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
          type: parameter.parameter.type,
          tag: tag?.toAssignTag(),
        )}';
        b.modifier = FieldModifier.final$;
        b.type = refer(_allocateTypeName(parameter.parameter.type));
      }));
    }).toList();
  }

  /// Returns arguments that can be used to call a constructor or method.
  /// [parameters] parameters used for arguments.
  Map<String, Expression> _buildArgumentsExpressions(
    List<ParameterElement> parameters,
    String? prefixScope,
  ) {
    if (parameters.isEmpty) {
      return HashMap<String, Expression>();
    }

    final Iterable<MapEntry<String, Expression>> entries =
        parameters.map((ParameterElement parameter) {
      return MapEntry<String, Expression>(
        parameter.name,
        _generateAssignExpression(
          type: parameter.type,
          tag: parameter.getQualifierAnnotationOrNull()?.tag,
          prefixScope: prefixScope,
        ),
      );
    });
    return Map<String, Expression>.fromEntries(entries);
  }

  // region disposable

  /// Builds a method which immediately registers disposable objects after the
  /// initialization of the component.
  Method _buildRegisterDisposableArgumentsMethod() {
    final List<DisposableInfo> arguments =
        _disposablesManager.disposableArguments;

    checkUnexpected(
      arguments.isNotEmpty,
      () => buildUnexpectedErrorMessage(
        message: 'disposable arguments is empty!',
      ),
    );

    Expression callExpression = const Reference('_disposableManager');

    for (final DisposableInfo info in arguments) {
      callExpression = callExpression.cascade('register').call(
        <Expression>[_buildDisposeMethodCall(info)],
      );
    }

    return Method(
      (MethodBuilder methodBuilder) {
        methodBuilder.name = '_registerDisposableArguments';
        methodBuilder.returns = const Reference('void');
        methodBuilder.body = callExpression.code;
      },
    );
  }

  /// Returns an expression in which the method is called to dispose of the
  /// object.
  /// Results:
  /// ````
  /// () => _i1.Module.disposeMyClass1(_myClass1)
  /// _myClass1.dispose
  /// ```
  Expression _buildDisposeMethodCall(DisposableInfo disposableInfo) {
    final DisposeHandler disposeHandler = disposableInfo.disposeHandler;
    if (disposeHandler is SelfDisposeHandler) {
      return _generateAssignExpression(
        type: disposableInfo.type,
        tag: disposableInfo.tag,
      ).property('dispose');
    } else if (disposeHandler is DelegateDisposeHandler) {
      final Expression body = refer(
        disposeHandler.method.enclosingElement.name!,
        createElementPath(disposeHandler.method.enclosingElement),
      ).property(disposeHandler.method.name).call(
        <Expression>[
          refer(
            '_${_generateFieldName(
              type: disposableInfo.type,
              tag: disposableInfo.tag?.toAssignTag(),
            )}',
          )
        ],
      );

      return Method((MethodBuilder builder) {
        builder
          ..body = body.code
          ..lambda = true;
      }).closure;
    }
    throw JuggerError(
      buildUnexpectedErrorMessage(
        message: 'Unknown dispose handler $disposeHandler',
      ),
    );
  }

  /// Returns an expression in which the object is instantiated and registered
  /// in the disposable manager. If the object doesn't need to be disposed,
  /// it simply returns the instantiation of the object.
  Expression _buildBodyWithRegisterDisposableOfType({
    required DartType type,
    required Code returnBlock,
  }) {
    final DisposableInfo? disposableInfo =
        _disposablesManager.findDisposableInfo(type, null);

    if (disposableInfo == null) {
      return Method(
        (MethodBuilder b) => b
          ..lambda = true
          ..body = returnBlock,
      ).closure;
    }
    return _buildCallDisposableFromInfo(
      returnBlock: returnBlock,
      info: disposableInfo,
    );
  }

  /// Returns an expression in which the object is instantiated and registered
  /// in the disposable manager. If the object doesn't need to be disposed,
  /// it simply returns the instantiation of the object.
  Expression _buildBodyWithRegisterDisposable({
    required ProvideMethod method,
    required Code returnBlock,
  }) {
    final DisposableInfo? disposableInfo = _disposablesManager
        .findDisposableInfo(method.element.returnType, method.tag);

    if (method.isDisposable) {
      check(
        disposableInfo != null,
        () => buildUnexpectedErrorMessage(
          message:
              'Method ${method.element.name} marked as disposable, but disposal handler not found.',
        ),
      );
      return _buildCallDisposableFromInfo(
        returnBlock: returnBlock,
        info: disposableInfo!,
      );
    } else {
      check(
        disposableInfo == null,
        () => buildUnexpectedErrorMessage(
          message:
              'Found disposal handler for method ${method.element.name}, but he does not marked as disposable.',
        ),
      );
    }

    return Method(
      (MethodBuilder b) => b
        ..lambda = true
        ..body = returnBlock,
    ).closure;
  }

  CodeExpression _buildCallDisposableFromInfo({
    required DisposableInfo info,
    required Code returnBlock,
  }) {
    return CodeExpression(
      Block.of(
        <Code>[
          ...<Code>[
            const Code('() {'),
            _buildCheckDisposed(),
            Code('${_allocateTypeName(info.type)} disposable = '),
            returnBlock,
            const Code(';'),
            _buildRegisterDisposableCall(info: info),
            const Code('return disposable;'),
            const Code('}'),
          ],
        ],
      ),
    );
  }

  Code _buildCheckDisposed() =>
      const Code('_disposableManager.checkDisposed();');

  Code _buildRegisterDisposableCall({
    required DisposableInfo info,
  }) {
    final DisposeHandler disposeHandler = info.disposeHandler;
    if (disposeHandler is SelfDisposeHandler) {
      return const Code('_disposableManager.register(disposable.dispose);');
    } else if (disposeHandler is DelegateDisposeHandler) {
      final Element moduleClass = disposeHandler.method.enclosingElement;
      return const Reference('_disposableManager')
          .property('register')
          .call(<Expression>[
        Method((MethodBuilder b) {
          b.body = refer(moduleClass.name!, createElementPath(moduleClass))
              .property(disposeHandler.method.name)
              .call(
            <Expression>[const CodeExpression(Code('disposable'))],
          ).code;
        }).closure,
      ]).statement;
    }

    throw JuggerError(
      buildUnexpectedErrorMessage(
        message: 'Unknown disposeHandler $disposeHandler',
      ),
    );
  }

  /// Builds the disposable manager field for the component implementation.
  Field _buildDisposableManagerField() {
    return Field(
      (FieldBuilder fieldBuilder) {
        fieldBuilder.name = '_disposableManager';
        fieldBuilder.type = const Reference('_DisposableManager');
        fieldBuilder.modifier = FieldModifier.final$;
        fieldBuilder.assignment =
            const Reference('_DisposableManager').newInstance(
          <Expression>[
            refer("'${_componentContext.component.element.name}'").expression,
          ],
        ).code;
      },
    );
  }

  /// Builds dispose method of Component.
  Method _buildDisposeMethod() {
    return Method(
      (MethodBuilder methodBuilder) {
        methodBuilder.annotations.add(_overrideAnnotationExpression);
        methodBuilder.name = 'dispose';
        methodBuilder.returns = const Reference('Future<void>');
        methodBuilder.body = const Code('_disposableManager.dispose()');
        methodBuilder.lambda = true;
      },
    );
  }

  /// Builds a disposable manager field that is used in the component
  /// implementation. Need to build only if the graph contains disposable
  /// objects.
  static Class buildDisposableManagerClass(Allocator allocator) {
    final String futureOr =
        allocator.allocate(const Reference('FutureOr', 'dart:async'));

    return Class(
      (ClassBuilder classBuilder) {
        classBuilder.name = '_DisposableManager';
        classBuilder.fields.addAll(
          <Field>[
            Field(
              (FieldBuilder fieldBuilder) {
                fieldBuilder.name = '_disposed';
                fieldBuilder.type = const Reference('bool');
                fieldBuilder.assignment = const Code('false');
              },
            ),
            Field(
              (FieldBuilder fieldBuilder) {
                fieldBuilder.name = '_componentName';
                fieldBuilder.type = const Reference('String');
                fieldBuilder.modifier = FieldModifier.final$;
              },
            ),
            Field(
              (FieldBuilder fieldBuilder) {
                fieldBuilder.name = '_disposables';
                fieldBuilder.type =
                    refer('List<$futureOr<dynamic> Function()>');
                fieldBuilder.assignment =
                    Code('<$futureOr<dynamic> Function()>[]');
              },
            ),
          ],
        );
        classBuilder.constructors.add(
          Constructor(
            (ConstructorBuilder builder) {
              builder.requiredParameters.add(
                Parameter(
                  (ParameterBuilder parameterBuilder) {
                    parameterBuilder.toThis = true;
                    parameterBuilder.name = '_componentName';
                  },
                ),
              );
            },
          ),
        );
        classBuilder.methods.addAll(
          <Method>[
            Method(
              (MethodBuilder methodBuilder) {
                methodBuilder.name = 'register';
                methodBuilder.returns = const Reference('void');
                methodBuilder.requiredParameters.add(
                  Parameter(
                    (ParameterBuilder parameterBuilder) {
                      parameterBuilder.name = 'disposable';
                      parameterBuilder.type = refer(
                        '$futureOr<dynamic> Function()',
                      );
                    },
                  ),
                );
                methodBuilder.body = Block.of(
                  <Code>[
                    const Code('assert(!_disposed);'),
                    const Code('_disposables.add(disposable);'),
                  ],
                );
              },
            ),
            Method(
              (MethodBuilder methodBuilder) {
                methodBuilder.name = 'checkDisposed';
                methodBuilder.returns = const Reference('void');
                methodBuilder.body = const Code(
                  r'''
if (_disposed) {
  throw StateError('${_componentName} accessed after dispose.');
}
                ''',
                );
              },
            ),
            Method(
              (MethodBuilder methodBuilder) {
                methodBuilder.name = 'dispose';
                methodBuilder.modifier = MethodModifier.async;
                methodBuilder.returns = const Reference('Future<void>');
                methodBuilder.body = Block.of(
                  <Code>[
                    const Code('if (_disposed) {'),
                    const Code('return;'),
                    const Code('}'),
                    const Code('_disposed = true;'),
                    Code(
                      'for ($futureOr<dynamic> Function() value in _disposables.reversed) {',
                    ),
                    const Code('await value.call();'),
                    const Code('}'),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

// endregion

// region multibindings

  Iterable<GraphObject> _collectMultibindingsObjects(MultibindingsGroup info) {
    return info.providers.map((ProviderSource provider) {
      return _componentContext.findGraphObject(
        type: provider.type,
        tag: provider.tag,
        multibindingsInfo: provider.multibindingsInfo,
      );
    });
  }

  Class _buildMultibindingsProviderClass(MultibindingsGroup group) {
    final GraphObject classGraphObject = group.graphObject;

    final Iterable<GraphObject> collectedObjects =
        _collectMultibindingsObjects(group);
    final Iterable<Field> fields = collectedObjects
        .map(
          (GraphObject graphObject) => Field((FieldBuilder fieldBuilder) {
            final String fieldTypeString = _allocator.allocate(
              refer(_allocateDependencyTypeName(graphObject)),
            );

            fieldBuilder
              ..type = refer('IProvider<$fieldTypeString>', _jugger)
              ..name = '_${_createMultibindingsProviderFieldName(
                type: graphObject.type,
                tag: graphObject.tag,
                multibindingsInfo: graphObject.multibindingsInfo,
              )}'
              ..late = true
              ..modifier = FieldModifier.final$;

            final ProviderSource provider = _componentContext.findProvider(
              graphObject.type,
              graphObject.tag,
              graphObject.multibindingsInfo,
            );

            if (provider is ModuleSource) {
              fieldBuilder.assignment =
                  _buildProviderFromMethod(provider.method, '_component').code;
            } else {
              throw JuggerError(
                buildUnexpectedErrorMessage(
                  message: 'Unexpected provider $provider',
                ),
              );
            }
          }),
        )
        .sortedBy((Field element) => element.name);

    final bool hasDependencies = collectedObjects
        .any((GraphObject object) => object.dependencies.isNotEmpty);

    final String classTypeString = _allocator.allocate(
      refer(_allocateDependencyTypeName(classGraphObject)),
    );

    return Class(
      (ClassBuilder classBuilder) {
        final GraphObject groupGraphObject = group.graphObject;
        classBuilder
          ..implements.add(refer('IProvider<$classTypeString>', _jugger))
          ..name = '_${_createMultibindingsProviderClassName(
            type: groupGraphObject.type,
            tag: groupGraphObject.tag,
            multibindingsInfo: groupGraphObject.multibindingsInfo,
          )}'
          ..fields.addAll(fields);
        if (hasDependencies) {
          classBuilder
            ..fields.add(
              Field(
                (FieldBuilder fieldBuilder) {
                  fieldBuilder
                    ..name = '_component'
                    ..type = refer(_thisComponentName)
                    ..modifier = FieldModifier.final$;
                },
              ),
            )
            ..constructors.add(
              Constructor(
                (ConstructorBuilder builder) {
                  builder.requiredParameters.add(
                    Parameter(
                      (ParameterBuilder parameterBuilder) {
                        parameterBuilder
                          ..toThis = true
                          ..name = '_component';
                      },
                    ),
                  );
                },
              ),
            );
        }

        final Code body;
        final DartType type = classGraphObject.type;

        if (type.isDartCoreMap) {
          body = _createMapBody(
            collectedObjects: collectedObjects,
            type: type as InterfaceType,
          ).code;
        } else if (type.isDartCoreSet) {
          body = _createSetBody(
            collectedObjects: collectedObjects,
            type: type as InterfaceType,
          ).code;
        } else {
          throw UnexpectedJuggerError('Unknown type $type');
        }

        classBuilder.methods.addAll(
          <Method>[
            Method(
              (MethodBuilder methodBuilder) {
                methodBuilder
                  ..annotations.add(_overrideAnnotationExpression)
                  ..name = 'get'
                  ..returns = refer(classTypeString)
                  ..body = body;
              },
            ),
          ],
        );
      },
    );
  }

  Expression _createMapBody({
    required Iterable<GraphObject> collectedObjects,
    required InterfaceType type,
  }) {
    final Iterable<MapEntry<Expression, Reference>> entries =
        collectedObjects.map((GraphObject graphObject) {
      final ModuleSource provider = _componentContext.findProvider(
        graphObject.type,
        graphObject.tag,
        graphObject.multibindingsInfo,
      ) as ModuleSource;

      final j.MultibindingsKeyAnnotation<Object?> keyAnnotation =
          provider.element.getSingleMultibindsKeyAnnotation();

      final Expression keyExpression;

      if (keyAnnotation is EnumAnnotation) {
        keyExpression = refer(
          '${_allocateTypeName(keyAnnotation.type)}.${keyAnnotation.key}',
        );
      } else if (keyAnnotation is MultibindingsKeyAnnotation<String>) {
        keyExpression = literalString(keyAnnotation.key);
      } else if (keyAnnotation is MultibindingsKeyAnnotation<int>) {
        keyExpression = literalNum(keyAnnotation.key);
      } else if (keyAnnotation is MultibindingsKeyAnnotation<double>) {
        keyExpression = literalNum(keyAnnotation.key);
      } else if (keyAnnotation is MultibindingsKeyAnnotation<bool>) {
        keyExpression = literalBool(keyAnnotation.key);
      } else if (keyAnnotation is MultibindingsKeyAnnotation<DartType>) {
        keyExpression = refer(
          _allocateTypeName(
            (keyAnnotation.key.element! as ClassElement).thisType,
          ),
        );
      } else {
        throw UnexpectedJuggerError(
          buildUnexpectedErrorMessage(
            message: 'Unknown keyAnnotation $keyAnnotation',
          ),
        );
      }

      final String fieldName = _createMultibindingsMemberProviderCall(
        type: graphObject.type,
        tag: graphObject.tag,
        multibindingsInfo: graphObject.multibindingsInfo,
      );

      return MapEntry<Expression, Reference>(keyExpression, refer(fieldName));
    });

    final Map<Expression, Reference> baseMap =
        Map<Expression, Reference>.fromEntries(entries);

    final SplayTreeMap<Expression, Reference> values =
        SplayTreeMap<Expression, Reference>.from(
      baseMap,
      (Expression key1, Expression key2) {
        final Reference ref1 = baseMap[key1]!;
        final Reference ref2 = baseMap[key2]!;
        return '${ref1.symbol}${ref1.symbol}'
            .compareTo('${ref2.symbol}${ref2.symbol}');
      },
    );

    return const Reference('Map').newInstanceNamed(
      'unmodifiable',
      <Expression>[
        CodeExpression(
          Block.of(
            <Code>[
              Code(
                '<${_allocateTypeName(type.typeArguments[0])}, '
                '${_allocateTypeName(type.typeArguments[1])}>',
              ),
              literalMap(values).code,
            ],
          ),
        ),
      ],
    );
  }

  Expression _createSetBody({
    required Iterable<GraphObject> collectedObjects,
    required InterfaceType type,
  }) {
    final Expression setExpression = literalSet(
      collectedObjects
          .map(
            (GraphObject o) => _createMultibindingsMemberProviderCall(
              type: o.type,
              tag: o.tag,
              multibindingsInfo: o.multibindingsInfo,
            ),
          )
          .sortedBy((String fieldName) => fieldName)
          .map((String fieldName) => refer(fieldName)),
    );
    return const Reference('Set').newInstanceNamed(
      'unmodifiable',
      <Expression>[
        CodeExpression(
          Block.of(
            <Code>[
              Code('<${_allocateTypeName(type.typeArguments[0])}>'),
              setExpression.code,
            ],
          ),
        ),
      ],
    );
  }

  String _createMultibindingsMemberProviderCall({
    required DartType type,
    required Tag? tag,
    required MultibindingsInfo? multibindingsInfo,
  }) {
    final StringBuffer fieldNameBuilder = StringBuffer()
      ..write('_')
      ..write(
        _generateFieldName(
          type: type,
          tag: tag?.toAssignTag(),
        ),
      );

    if (multibindingsInfo != null) {
      fieldNameBuilder.write(
        generateMd5(multibindingsInfo.methodPath),
      );
    }

    fieldNameBuilder.write('Provider.get()');
    return fieldNameBuilder.toString();
  }

  String _createMultibindingsProviderClassName({
    required DartType type,
    required Tag? tag,
    required MultibindingsInfo? multibindingsInfo,
  }) {
    final StringBuffer fieldNameBuilder = StringBuffer();
    fieldNameBuilder.write(
      _generateFieldName(
        type: type,
        tag: tag?.toAssignTag(),
      ),
    );
    if (multibindingsInfo != null) {
      fieldNameBuilder.write(
        _uniqueIdGenerator.generate(multibindingsInfo.methodPath),
      );
    }
    final String componentName = _componentContext.component.element.name;
    fieldNameBuilder
      ..write(componentName)
      ..write('_')
      ..write(_uniqueIdGenerator.generate(componentName))
      ..write('_')
      ..write('Provider');

    return capitalize(fieldNameBuilder.toString());
  }

  String _createMultibindingsProviderFieldName({
    required DartType type,
    required Tag? tag,
    required MultibindingsInfo? multibindingsInfo,
  }) {
    final StringBuffer fieldNameBuilder = StringBuffer();
    fieldNameBuilder.write(
      _generateFieldName(
        type: type,
        tag: tag?.toAssignTag(),
      ),
    );
    if (multibindingsInfo != null) {
      fieldNameBuilder.write(
        generateMd5(multibindingsInfo.methodPath),
      );
    }
    fieldNameBuilder.write('Provider');

    return fieldNameBuilder.toString();
  }

// endregion multibindings
}
