import '../jugger_error.dart';

extension ObjectExt on Object? {
  T requiredType<T>() {
    if (this is T) {
      return this as T;
    }
    throw UnexpectedJuggerError('Expected type $T, but was $this');
  }
}
