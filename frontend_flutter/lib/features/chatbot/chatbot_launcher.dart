import 'package:flutter/material.dart';
import 'package:crop_price_predictor/l10n/app_localizations.dart';

import 'chatbot_screen.dart';

void openChatbot(
  BuildContext context, {
  Map<String, dynamic>? chatContext,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ChatbotScreen(initialContext: chatContext),
    ),
  );
}

class ChatbotFab extends StatelessWidget {
  const ChatbotFab({
    super.key,
    required this.heroTag,
    this.chatContext,
  });

  final String heroTag;
  final Map<String, dynamic>? chatContext;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: heroTag,
      onPressed: () => openChatbot(context, chatContext: chatContext),
      icon: const Icon(Icons.smart_toy_outlined),
      label: Text(AppLocalizations.of(context).navAssistant),
    );
  }
}
