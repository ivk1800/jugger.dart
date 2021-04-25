import '../jugger.dart';

abstract class IProvider<T> {
  T get();
}

typedef Builder<T> = T Function();

class Provider<T> implements IProvider<T> {
  Provider(Builder<T> builder) : _builder = builder;

  final Builder<T> _builder;

  @override
  T get() {
    return _builder();
  }
}

class SingletonProvider<T> implements IProvider<T> {
  SingletonProvider(Builder<T> builder) : _builder = builder;

  final Builder<T> _builder;

  T? value;

  @override
  T get() {
    value ??= _builder();
    return value!;
  }
}

class DisposableProvider<T> implements IProvider<T> {
  DisposableProvider(this._disposableBag, this._sourceProvider);

  final IProvider<T> _sourceProvider;
  final IDisposableBag _disposableBag;

  @override
  T get() {
    final T value = _sourceProvider.get();
    // ignore: avoid_as
    _disposableBag.registerDisposable(value as IDisposable);
    return value;
  }
}
