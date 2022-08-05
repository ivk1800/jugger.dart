/// Provides instances of [T]. Typically implemented by an injector.
abstract class IProvider<T> {
  T get();
}

typedef Builder<T> = T Function();

/// Call to [Provider.get] returns a new instance.
class Provider<T> implements IProvider<T> {
  Provider(Builder<T> builder) : _builder = builder;

  final Builder<T> _builder;

  @override
  T get() {
    return _builder();
  }
}

/// Call to [SingletonProvider.get] computes value and remembers that same value
/// for all calls to [SingletonProvider.get] per scope.
class SingletonProvider<T> implements IProvider<T> {
  SingletonProvider(Builder<T> builder) : _builder = builder;

  final Builder<T> _builder;

  late final T value = _builder();

  @override
  T get() => value;
}
