import 'package:jugger/jugger.dart';

/// A handle to a lazily-computed value. Each [ILazy] computes its value on the
/// first call to [ILazy.get] and remembers that same value for all subsequent
/// calls to [ILazy.get].
abstract class ILazy<T> {
  T get();
}

/// Lazy provider based.
class Lazy<T> implements ILazy<T> {
  Lazy(this._provider);

  final IProvider<T> _provider;

  late final T value = _provider.get();

  @override
  T get() => value;
}
