sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class UnimplementedFeatureException extends AppException {
  const UnimplementedFeatureException(super.message);
}

final class DataSourceException extends AppException {
  const DataSourceException(super.message);
}

final class DuplicateCatalogException extends AppException {
  const DuplicateCatalogException(super.message);
}
