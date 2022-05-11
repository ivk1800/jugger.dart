/// Config of JuggerBuilder.
class GlobalConfig {
  GlobalConfig({
    required this.removeInterfacePrefixFromComponentName,
    required this.checkUnusedProviders,
  });

  final bool removeInterfacePrefixFromComponentName;
  final bool checkUnusedProviders;
}
