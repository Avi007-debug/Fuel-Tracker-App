import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:fuel_tracker_app/app/theme.dart';
import 'package:fuel_tracker_app/core/ai/llm_service.dart';
import 'package:fuel_tracker_app/features/ai_chat/controller.dart';
import 'package:fuel_tracker_app/core/notifications/notification_service.dart';

/// Floating AI Chat screen — styled like ChatGPT, running Qwen2.5 offline.
class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  // Voice Recognition
  late stt.SpeechToText _speech;
  bool _speechAvailable = false;
  AnimationController? _micAnimationController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    _micAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Initialise the LLM model (copies from assets/models/ on first launch)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiChatProvider.notifier).initLlm();
    });
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onError: (val) => print('Speech init error: $val'),
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            ref.read(aiChatProvider.notifier).setListening(false);
          }
        },
      );
      if (mounted) {
        setState(() {
          _speechAvailable = available;
        });
      }
    } catch (e) {
      print('Speech recognition failed to initialize: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _micAnimationController?.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    _messageController.clear();
    ref.read(aiChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _sendSuggestion(String text) {
    ref.read(aiChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _toggleListening() async {
    final notifier = ref.read(aiChatProvider.notifier);
    final state = ref.read(aiChatProvider);

    if (state.isListening) {
      await _speech.stop();
      notifier.setListening(false);
      _sendMessage();
    } else {
      if (!_speechAvailable) {
        await _initSpeech();
      }

      if (_speechAvailable) {
        notifier.setListening(true);
        await _speech.listen(
          onResult: (val) {
            setState(() {
              _messageController.text = val.recognizedWords;
            });
            if (val.finalResult) {
              notifier.setListening(false);
              _sendMessage();
            }
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition is not available on this device.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Antigravity AI', style: Theme.of(context).textTheme.titleMedium),
                Text(
                  chatState.llmState == LlmState.ready ? 'Offline (Local Model)' : 'Initializing...',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: chatState.llmState == LlmState.ready ? AppTheme.accentGreen : AppTheme.accentOrange,
                      ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notification_important_outlined, color: Theme.of(context).colorScheme.onSurface.withAlpha(180)),
            onPressed: () {
              final isReady = chatState.llmState == LlmState.ready;
              NotificationService.instance.showModelStatus(isReady);
            },
            tooltip: 'Check Model Status',
          ),
          if (chatState.messages.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_outlined, color: Theme.of(context).colorScheme.onSurface.withAlpha(180)),
              onPressed: () => ref.read(aiChatProvider.notifier).clearChat(),
              tooltip: 'Clear history',
            ),
        ],
      ),
      body: _buildBody(chatState),
    );
  }

  Widget _buildBody(AiChatState chatState) {
    // If model is preparing, show initialization loader
    if (chatState.llmState == LlmState.copyingFromAssets || chatState.llmState == LlmState.initializingEngine) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  color: AppTheme.accentGreen,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                chatState.llmState == LlmState.copyingFromAssets ? 'Setting Up Offline AI' : 'Loading AI Engine',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              if (chatState.llmState == LlmState.copyingFromAssets) ...[
                LinearProgressIndicator(
                  value: chatState.copyProgress,
                  backgroundColor: Theme.of(context).colorScheme.outline,
                  color: AppTheme.accentGreen,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(chatState.copyProgress * 100).toStringAsFixed(0)}% copied (one-time setup)...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                ),
              ] else ...[
                Text(
                  'Starting local llama.cpp core...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // ── Messages / Empty State ──────────────────────────────────────────
        Expanded(
          child: chatState.messages.isEmpty
              ? _ChatGPTIntro(onSuggestionTap: _sendSuggestion)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: chatState.messages.length,
                  itemBuilder: (_, i) {
                    final msg = chatState.messages[i];
                    return _ChatGPTMessageBubble(
                      message: msg,
                      isLast: i == chatState.messages.length - 1,
                      isGenerating: chatState.isGenerating,
                    );
                  },
                ),
        ),

        // ── Listening Waveform Overlay ──────────────────────────────────────
        if (chatState.isListening)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: AppTheme.accentRed.withAlpha(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _micAnimationController!,
                  builder: (_, __) {
                    return Row(
                      children: List.generate(5, (index) {
                        final height = 5.0 + 20.0 * sin((_micAnimationController!.value * 2 * pi) + (index * 0.8));
                        return Container(
                          width: 3,
                          height: max(3.0, height),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentRed,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  'Listening... Speak now',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.accentRed,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),

        // ── Text Input Bar ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Voice Dictation
                IconButton(
                  icon: Icon(
                    chatState.isListening ? Icons.mic : Icons.mic_none,
                    color: chatState.isListening ? AppTheme.accentRed : Theme.of(context).colorScheme.onSurface.withAlpha(180),
                  ),
                  onPressed: _toggleListening,
                  tooltip: 'Voice Query',
                ),
                const SizedBox(width: 4),
                
                // Input TextField
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Ask Antigravity (e.g. range, mileage)...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        borderSide: const BorderSide(color: AppTheme.accentGreen),
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Circular Send
                IconButton.filled(
                  onPressed: chatState.isGenerating ? null : _sendMessage,
                  icon: chatState.isGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_upward, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Minimalist ChatGPT Intro Landing State
class _ChatGPTIntro extends StatelessWidget {
  final ValueChanged<String> onSuggestionTap;

  const _ChatGPTIntro({required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    final list = [
      'What is my range?',
      'Show my mileage trend',
      'Is engine oil service due?',
      'Give me today\'s summary',
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: AppTheme.accentGreen, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'Antigravity Companion',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your offline Activa assistant. Powered by a local Qwen2.5 LLM. Injected with your live ride logs and performance statistics.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            // Suggested Prompts
            Text(
              'Suggestions',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                  ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (_, i) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    side: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    onTap: () => onSuggestionTap(list[i]),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 16, color: AppTheme.accentGreen.withAlpha(180)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              list[i],
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(60)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// ChatGPT-like Message Bubble (No backgrounds for bot, clean backgrounds for user)
class _ChatGPTMessageBubble extends StatelessWidget {
  final AiChatMessage message;
  final bool isLast;
  final bool isGenerating;

  const _ChatGPTMessageBubble({
    required this.message,
    required this.isLast,
    required this.isGenerating,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Text(
                message.text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    // Bot message with no background and simple icon
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bot Profile Icon
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 14),
          
          // Markdown message text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.text.isEmpty && isLast && isGenerating)
                  _buildTypingIndicator()
                else
                  _buildFormattedMessage(context, message.text),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return _BouncingDot(delay: i * 150);
        }),
      ),
    );
  }

  Widget _buildFormattedMessage(BuildContext context, String text) {
    // Custom simple parser to render basic bold markdown in Qwen answers
    final parts = text.split('**');
    final spans = <TextSpan>[];
    
    for (int i = 0; i < parts.length; i++) {
      final isBold = i % 2 == 1;
      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: isBold ? AppTheme.accentGreen : null,
        ),
      ));
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
              fontSize: 15,
            ),
      ),
    );
  }
}

/// Helper Bouncing Dot for Typing Indicator
class _BouncingDot extends StatefulWidget {
  final int delay;
  const _BouncingDot({required this.delay});

  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
