import 'package:flutter/material.dart';

@immutable
class Config {
  const Config({required this.packagesRepositoryType});

  final PackagesRepositoryType packagesRepositoryType;
}

enum PackagesRepositoryType {
  $default,
  broken,
}
