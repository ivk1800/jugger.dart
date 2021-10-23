library jugger;

export 'src/annotations.dart'
    show
        module,
        provide,
        singleton,
        inject,
        Component,
        Inject,
        bind,
        nonLazy,
        componentBuilder,
        Named;

export 'src/disposable.dart';
export 'src/provider.dart'
    show Provider, SingletonProvider, IProvider, DisposableProvider;
