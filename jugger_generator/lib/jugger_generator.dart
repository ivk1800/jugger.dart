import 'package:build/build.dart';

import 'src/builder/jugger_builder.dart';

Builder componentBuilder(BuilderOptions options) =>
    JuggerBuilder(options: options);
