/// Config of JuggerBuilder.
class GlobalConfig {
  GlobalConfig({
    required this.removeInterfacePrefixFromComponentName,
    required this.checkUnusedProviders,
    required this.lineLength,
  });

  /// Whether to remove the prefix from the component name if it starts with 'I'.
  final bool removeInterfacePrefixFromComponentName;

  /// Whether to check the generated code for unused providers. These are
  /// providers that are not used in the object graph.
  final bool checkUnusedProviders;

  /// The number of characters allowed in a single line of generated file.
  final int lineLength;
}
