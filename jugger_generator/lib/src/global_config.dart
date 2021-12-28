class GlobalConfig {
  GlobalConfig({
    required this.ignoreInterfacePrefixInComponentName,
    required this.checkUnusedProviders,
  });

  final bool ignoreInterfacePrefixInComponentName;
  final bool checkUnusedProviders;
}
