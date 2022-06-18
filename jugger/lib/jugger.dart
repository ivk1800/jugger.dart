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
        Named;

export 'src/provider.dart' show Provider, SingletonProvider, IProvider;
