/// A KDBX error that can be thrown.
sealed class KdbxError implements Exception {
  final String _message;
  const KdbxError([String message = '']) : _message = message;

  /// The description of the error.
  get message => _message;
}

/// A error thrown if a KDBX file corruption detected.
class FileCorruptedError extends KdbxError {
  /// Creates a [FileCorruptedError] with [message].
  const FileCorruptedError(String message) : super('File corrupted: $message');
}

/// A error thrown while attempting to set an unsupported value.
class UnsupportedValueError extends KdbxError {
  /// Creates a [UnsupportedValueError] with [message].
  const UnsupportedValueError(String message)
      : super('Not supported value: $message');
}

/// A error thrown if an invalid state detected.
class InvalidStateError extends KdbxError {
  /// Creates a [InvalidStateError] with [message].
  const InvalidStateError(String message) : super('Invalid state: $message');
}

/// A error thrown if credentials are invalid.
class InvalidCredentialsError extends KdbxError {
  /// Creates a [InvalidCredentialsError] with [message].
  const InvalidCredentialsError(String message)
      : super('Invalid credentials: $message');
}

/// A error thrown while attempting to merge.
class MergeError extends KdbxError {
  /// Creates a [MergeError] with [message].
  const MergeError(String message) : super('Merge error: $message');
}
