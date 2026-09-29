import 'package:flutter/material.dart';
import 'package:crop_price_predictor/l10n/app_localizations.dart';

import '../../l10n/l10n.dart';
import '../../models/chat_model.dart';
import '../../services/api_service.dart';
import '../../services/app_locale_controller.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({
    super.key,
    this.initialContext,
  });

  final Map<String, dynamic>? initialContext;

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final String _sessionId;
  bool _sending = false;
  late List<ChatMessageModel> _messages;
  late List<String> _suggestions;

  @override
  void initState() {
    super.initState();
    _sessionId = 'chat-${DateTime.now().microsecondsSinceEpoch}';
    _messages = const [];
    _suggestions = const [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_messages.isEmpty) {
      final l10n = AppLocalizations.of(context);
      _messages = [
        ChatMessageModel(
          role: 'assistant',
          text: l10n.assistantInitialMessage,
        ),
      ];
      _suggestions = [
        l10n.assistantSuggestionCrops,
        l10n.assistantSuggestionMarkets,
        l10n.assistantSuggestionBestTime,
      ];
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _subtitleLine() {
    final l10n = AppLocalizations.of(context);
    final language = AppLocaleScope.of(context).language;
    final cropName = widget.initialContext?['crop_name'] as String?;
    final market = widget.initialContext?['market'] as String?;
    final languageLabel = '${language.nativeName} (${language.englishName})';

    if (cropName == null || cropName.trim().isEmpty) {
      return '${l10n.chatbotSubtitle}\n$languageLabel';
    }

    if (market != null && market.trim().isNotEmpty) {
      return '${l10n.chatbotSubtitle}\n${l10n.fieldCrop}: $cropName • ${l10n.fieldMarket}: $market\n$languageLabel';
    }

    return '${l10n.chatbotSubtitle}\n${l10n.fieldCrop}: $cropName\n$languageLabel';
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _sending) {
      return;
    }

    _controller.clear();
    setState(() {
      _sending = true;
      _messages = [..._messages, ChatMessageModel(role: 'user', text: text)];
    });
    _scrollToBottom();

    try {
      final response = await _api.sendChatMessage(
        message: text,
        sessionId: _sessionId,
        language: AppLocaleScope.of(context).apiLanguageTag,
        context: widget.initialContext,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages = [
          ..._messages,
          ChatMessageModel(role: 'assistant', text: response.reply),
        ];
        _suggestions = response.suggestions;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _messages = [
          ..._messages,
          ChatMessageModel(
            role: 'assistant',
            text: AppLocalizations.of(context).chatbotError,
          ),
        ];
      });
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeController = AppLocaleScope.of(context);
    final currentLanguage = localeController.language;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chatbotTitle),
        actions: [
          PopupMenuButton<AppLanguage>(
            tooltip: l10n.labelLanguage,
            initialValue: currentLanguage,
            icon: const Icon(Icons.language_outlined),
            onSelected: (language) => localeController.setLanguage(language),
            itemBuilder: (context) {
              return L10n.supportedLanguages
                  .map(
                    (language) => PopupMenuItem<AppLanguage>(
                      value: language,
                      child: Text(
                        '${language.nativeName} (${language.englishName})',
                      ),
                    ),
                  )
                  .toList();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _subtitleLine(),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: const Color(0xFF617080)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Verified answers are grounded in crop, market, and weather data. If the app cannot confirm something, it will say so.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF617080),
                    ),
              ),
            ),
            if (_suggestions.isNotEmpty)
              SizedBox(
                height: 42,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    return ActionChip(
                      label: Text(suggestion),
                      onPressed: _sending ? null : () => _send(suggestion),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _messages.isEmpty
                  ? Center(child: Text(l10n.chatbotEmpty))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      itemCount: _messages.length + (_sending ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_sending && index == _messages.length) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF2E8),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }

                        final message = _messages[index];
                        final isUser = message.role == 'user';
                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            constraints: const BoxConstraints(maxWidth: 520),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Theme.of(context).colorScheme.primary
                                  : const Color(0xFFF1F5F7),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              message.text,
                              style: TextStyle(
                                color: isUser
                                    ? Colors.white
                                    : const Color(0xFF1C2E33),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: l10n.chatbotHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    child: Text(
                      _sending ? l10n.buttonSending : l10n.buttonSend,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
