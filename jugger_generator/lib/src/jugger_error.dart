/// General generation error.
class JuggerError extends Error {
  JuggerError(this.message);

  final String message;

  @override
  String toString() => 'error: $message';
}

class UnexpectedJuggerError extends Error {
  UnexpectedJuggerError(this.message);

  final String message;

  @override
  String toString() => message;
}
