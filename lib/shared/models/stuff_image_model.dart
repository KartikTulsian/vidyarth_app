class StuffImage {
  final String id;
  final String? stuffId;
  final String url;
  final bool isPrimary;

  StuffImage({
    required this.id,
    this.stuffId,
    required this.url,
    this.isPrimary = false,
  });

  factory StuffImage.fromMap(Map<String, dynamic> map) => StuffImage(
    id: map['id'],
    stuffId: map['stuff_id'],
    url: map['url'] ?? '',
    isPrimary: map['is_primary'] ?? false,
  );
}