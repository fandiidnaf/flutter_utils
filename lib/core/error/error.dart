class AppError implements Exception {
  final int statusCode;
  final String message;

  const AppError({required this.message, this.statusCode = -1});
}
