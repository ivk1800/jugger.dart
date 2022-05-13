/// Config of JuggerBuilder.
class GlobalConfig {
  GlobalConfig({
    required this.removeInterfacePrefixFromComponentName,
    required this.checkUnusedProviders,
  });

  /// Whether to remove the prefix from the component name if it starts with 'I'.
  final bool removeInterfacePrefixFromComponentName;

  /// Whether to check the generated code for unused providers. These are
  /// providers that are not used in the object graph.
  final bool checkUnusedProviders;
}
