class Tag {
  const Tag({
    required this.uniqueId,
    required this.originalId,
  });

  /// For internal usage.
  final String uniqueId;

  /// Can be displayed for user.
  final String originalId;

  @override
  bool operator ==(dynamic other) => other is Tag && uniqueId == other.uniqueId;

  @override
  int get hashCode => uniqueId.hashCode;

  @override
  String toString() => uniqueId;
}
