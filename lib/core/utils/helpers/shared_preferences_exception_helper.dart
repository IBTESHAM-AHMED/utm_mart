class SharedPreferencesException implements Exception {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  SharedPreferencesException(this.message, {this.error, this.stackTrace});

  @override
  String toString() => message;
}

class SharedPreferencesExceptionHelper {
  static String handleException(dynamic error) {
    if (error is FormatException) {
      return "Error in stored data format"; // Updated to English
    } else if (error is TypeError) {
      return "Error in stored data type"; // Updated to English
    } else {
      return "An unexpected error occurred while accessing local data"; // Updated to English
    }
  }
}
