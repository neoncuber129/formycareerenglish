bool shouldAttemptLocalCaptureUpload(String imageAnchor) {
  final trimmed = imageAnchor.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return false;
  }
  return true;
}
