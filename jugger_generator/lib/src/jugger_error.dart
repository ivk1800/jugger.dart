import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import 'generator/tag.dart';

/// General generation error.
class JuggerError extends Error {
  JuggerError(this.message, [this.element]);

  final String message;

  final Element? element;

  @override
  String toString() => 'error: $message';
}

class UnexpectedJuggerError extends Error {
  UnexpectedJuggerError(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProviderNotFoundError extends JuggerError {
  ProviderNotFoundError({
    required this.type,
    required this.tag,
    required String message,
  }) : super(message);

  final DartType type;
  final Tag? tag;
}
