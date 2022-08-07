library jugger;

export 'src/annotations.dart'
    show
        module,
        Module,
        provides,
        singleton,
        inject,
        disposalHandler,
        Disposable,
        disposable,
        DisposalStrategy,
        Component,
        Inject,
        binds,
        nonLazy,
        componentBuilder,
        qualifier,
        intoSet,
        intoMap,
        mapKey,
        StringKey,
        IntKey,
        TypeKey,
        Subcomponent,
        subcomponentFactory,
        scope,
        Named;

export 'src/provider.dart' show Provider, SingletonProvider, IProvider;
export 'src/lazy.dart' show ILazy;
export 'src/provider_extensions.dart';
