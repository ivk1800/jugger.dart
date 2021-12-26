import 'package:analyzer/dart/element/element.dart';

extension LibraryElementExt on LibraryElement {
  bool get isJuggerLibrary => location!.components.any(
        (String component) =>
            component == 'package:jugger/src/annotations.dart',
      );
}
