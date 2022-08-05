import 'package:jugger/jugger.dart';
import 'package:jugger/src/lazy.dart';

extension ProviderExtensions<T> on IProvider<T> {
  /// Converts [IProvider] to [ILazy].
  ILazy<T> toLazy() => Lazy(this);
}
