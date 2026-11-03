import '../generated/protocol.dart';
import '../hub/vault_import.dart';

/// Memastikan [path] relatif, tanpa `..`, dan berakhiran `.md`.
String safePath(String path) {
  if (!isSafeRelative(path) ||
      !path.toLowerCase().endsWith('.md') ||
      path.split('/').contains('.git')) {
    throw WhiskerException(message: 'Path dokumen tidak valid: $path');
  }
  return path;
}
