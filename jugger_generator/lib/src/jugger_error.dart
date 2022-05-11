/// General generation error.
class JuggerError extends Error {
  JuggerError(this.message);

  final String message;

  @override
  String toString() => 'error: $message';
}
