extension IterableExt<T> on Iterable<T> {
  int firstIndexWhere(bool Function(T element) test) {
    int index = 0;
    for (final T element in this) {
      if (test(element)) return index;
      index++;
    }
    return -1;
  }
}
