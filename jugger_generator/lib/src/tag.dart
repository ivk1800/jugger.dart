class Tag {
  Tag._(this.uniqueId);

  factory Tag.ofString(String s) {
    return Tag._(s);
  }

  final String uniqueId;

  @override
  bool operator ==(dynamic other) => other is Tag && uniqueId == other.uniqueId;

  @override
  int get hashCode => uniqueId.hashCode;

  @override
  String toString() => uniqueId;
}
