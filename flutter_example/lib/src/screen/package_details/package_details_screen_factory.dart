import 'package:flutter/material.dart';
import 'package:jugger/jugger.dart' as j;

class PackageDetailsScreenFactory {
  @j.inject
  PackageDetailsScreenFactory();

  Widget create(String name) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: const Center(
        child: Text('not implemented'),
      ),
    );
  }
}
