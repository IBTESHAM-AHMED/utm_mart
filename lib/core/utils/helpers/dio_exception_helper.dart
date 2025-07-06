import 'package:dio/dio.dart';

class DioExceptionHelper {
  static String handleDioError(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return "Connection timeout. Please check your internet connection.";
      case DioExceptionType.sendTimeout:
        return "Sending the request took too long. Please check your internet connection.";
      case DioExceptionType.receiveTimeout:
        return "The server took too long to respond. Please try again later.";
      case DioExceptionType.badResponse:
        return _handleBadResponse(dioException.response);
      case DioExceptionType.cancel:
        return "The request was canceled. Please try again.";
      case DioExceptionType.unknown:
        return dioException.message!.contains("SocketException")
            ? "It seems you're offline. Please check your connection."
            : "An unexpected error occurred. Please try again.";
      default:
        return "An unexpected error occurred. Please try again.";
    }
  }

  static String _handleBadResponse(Response? response) {
    if (response != null) {
      switch (response.statusCode) {
        case 400:
          return "Bad request. Please check your inputs.";
        case 401:
          return "Unauthorized. Please verify your login credentials.";
        case 403:
          return "Access denied.";
        case 404:
          return "Resource not found.";
        case 500:
          return "Server error. Please try again later.";
        case 503:
          return "Service unavailable. Please try again later.";
        default:
          return "Unexpected error: ${response.statusCode}. Please try again.";
      }
    }
    return "An unexpected error occurred from the server. Please try again later.";
  }
}
