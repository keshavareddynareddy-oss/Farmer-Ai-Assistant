class CropModel {
  const CropModel({
    required this.id,
    required this.name,
    this.market = '',
  });

  final String id;
  final String name;
  final String market;

  factory CropModel.fromJson(Map<String, dynamic> json) {
    return CropModel(
      id: json['id'] as String,
      name: json['name'] as String,
      market: json['market'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'market': market,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is CropModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
