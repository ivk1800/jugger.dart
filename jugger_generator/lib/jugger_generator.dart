library jugger_generator;

import 'package:build/build.dart';

import 'src/jugger_builder.dart';

Builder componentBuilder(BuilderOptions options) =>
    JuggerBuilder(options: options);
