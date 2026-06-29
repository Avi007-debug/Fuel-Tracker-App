import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AI Chat controller — will handle LLM context injection and inference in v2.0.
class AiChatController {
  final Ref _ref;

  AiChatController(this._ref);

  // TODO: Implement in v2.0:
  // - Context builder (serialize 30-day rider data)
  // - System prompt engineering for Qwen2.5
  // - Streaming token output
  // - Session memory (multi-turn context)
}
