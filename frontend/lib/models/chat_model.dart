class ChatMessageModel {
  const ChatMessageModel({
    required this.role,
    required this.text,
  });

  final String role;
  final String text;
}

class ChatResponseModel {
  const ChatResponseModel({
    required this.sessionId,
    required this.language,
    required this.reply,
    required this.suggestions,
    this.confidence,
    this.source,
  });

  final String sessionId;
  final String language;
  final String reply;
  final List<String> suggestions;
  final String? confidence;
  final String? source;

  factory ChatResponseModel.fromJson(Map<String, dynamic> json) {
    return ChatResponseModel(
      sessionId: json['session_id'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      reply: json['reply'] as String? ?? '',
      suggestions: (json['suggestions'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(),
      confidence: json['confidence'] as String?,
      source: json['source'] as String?,
    );
  }
}
