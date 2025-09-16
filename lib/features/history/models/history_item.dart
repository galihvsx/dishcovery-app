class HistoryItem {
  final String dish;
  final String origin;
  final String description;
  final String image;

  const HistoryItem({
    required this.dish,
    required this.origin,
    required this.description,
    required this.image,
  });

  // Optional: dari Map (kalau nanti ambil dari JSON / DB)
  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      dish: map['dish'] as String,
      origin: map['origin'] as String,
      description: map['description'] as String,
      image: map['image'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dish': dish,
      'origin': origin,
      'description': description,
      'image': image,
    };
  }
}
