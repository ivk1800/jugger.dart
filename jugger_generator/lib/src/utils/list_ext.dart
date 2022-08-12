import 'package:collection/collection.dart';

extension ListExt<E> on List<E> {
  bool anyInstance<T>() => any((E element) => element is T);

  T? firstInstanceOrNull<T>() =>
      firstWhereOrNull((E element) => element is T) as T?;
}
