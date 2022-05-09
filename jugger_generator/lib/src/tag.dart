/// Simplified representation of the qualifier. uniqueId and originalId must be
/// generated by the client.
class Tag {
  const Tag({
    required this.uniqueId,
    required this.originalId,
  });

  /// For internal usage. This field must be used for identification.
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
