class ProfileIncompleteException implements Exception {
  final String message;
  final List<String> missingFields;

  ProfileIncompleteException({
    required this.message,
    required this.missingFields,
  });

  @override
  String toString() => message;
}