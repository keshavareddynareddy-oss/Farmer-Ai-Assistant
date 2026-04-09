class SoilRecommendationModel {
  const SoilRecommendationModel({
    required this.summary,
    required this.recommendations,
  });

  final String summary;
  final List<String> recommendations;

  factory SoilRecommendationModel.fromJson(Map<String, dynamic> json) {
    return SoilRecommendationModel(
      summary: json['summary'] as String? ?? '',
      recommendations:
          (json['recommendations'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item as String)
              .toList(),
    );
  }
}
