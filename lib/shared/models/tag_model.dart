class Tag {
  final String id;
  final String name;

  Tag({required this.id, required this.name});

  factory Tag.fromMap(Map<String, dynamic> map) => Tag(
    id: map['tag_id'],
    name: map['name'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'name': name,
  };
}