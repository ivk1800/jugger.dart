import 'package:jugger/jugger.dart';

/// A handle to a lazily-computed value. Each [ILazy] computes its value on the
/// first call to [ILazy.value] and remembers that same value for all subsequent
/// calls to [ILazy.value].
abstract class ILazy<T> {
  T get value;
}

/// Lazy provider based.
class Lazy<T> implements ILazy<T> {
  Lazy(this._provider);

  final IProvider<T> _provider;

  late final T _value = _provider.get();

  @override
  T get value => _value;
}
