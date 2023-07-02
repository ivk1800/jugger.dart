int compareNullable<T extends Comparable<T>>(T? a, T? b) {
  if (a != null && b == null) {
    return 1;
  } else if (a == null && b != null) {
    return -1;
  } else if (a != null && b != null) {
    return a.compareTo(b);
  } else {
    return 0;
  }
}
