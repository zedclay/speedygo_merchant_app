final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

bool isPlausibleSourceId(String? sourceId) {
  if (sourceId == null || sourceId.isEmpty) {
    return false;
  }
  if (sourceId.contains('/') ||
      sourceId.contains('\\') ||
      sourceId.contains('://') ||
      sourceId.contains('?') ||
      sourceId.contains('#')) {
    return false;
  }
  return _uuidPattern.hasMatch(sourceId);
}
