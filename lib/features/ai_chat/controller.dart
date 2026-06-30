import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/core/ai/llm_service.dart';
import 'package:fuel_tracker_app/models/trip.dart';
import 'package:fuel_tracker_app/models/fuel_entry.dart';
import 'package:fuel_tracker_app/providers/app_providers.dart';

/// Single chat message model.
class AiChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  AiChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

/// AI Chat state model.
class AiChatState {
  final List<AiChatMessage> messages;
  final bool isGenerating;
  final LlmState llmState;
  final double copyProgress;
  final bool isListening;

  AiChatState({
    required this.messages,
    required this.isGenerating,
    required this.llmState,
    required this.copyProgress,
    required this.isListening,
  });

  AiChatState copyWith({
    List<AiChatMessage>? messages,
    bool? isGenerating,
    LlmState? llmState,
    double? copyProgress,
    bool? isListening,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
      llmState: llmState ?? this.llmState,
      copyProgress: copyProgress ?? this.copyProgress,
      isListening: isListening ?? this.isListening,
    );
  }
}

/// Riverpod provider for AI Chat State.
final aiChatProvider = StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
  return AiChatNotifier(ref);
});

/// AI Chat State Notifier.
class AiChatNotifier extends StateNotifier<AiChatState> {
  final Ref _ref;
  late final LlmService _llmService;
  StreamSubscription? _stateSub;
  StreamSubscription? _progressSub;

  AiChatNotifier(this._ref)
      : super(AiChatState(
          messages: [],
          isGenerating: false,
          llmState: LlmState.notInitialized,
          copyProgress: 0.0,
          isListening: false,
        )) {
    _llmService = _ref.read(llmServiceProvider);

    _stateSub = _llmService.stateStream.listen((stateVal) {
      state = state.copyWith(llmState: stateVal);
    });
    _progressSub = _llmService.progressStream.listen((progressVal) {
      state = state.copyWith(copyProgress: progressVal);
    });

    state = state.copyWith(
      llmState: _llmService.state,
      copyProgress: _llmService.copyProgress,
    );
  }

  /// Trigger LLM initialisation (asset copying or loading).
  Future<void> initLlm() async {
    await _llmService.init();
  }

  /// Update recording listening state.
  void setListening(bool listening) {
    state = state.copyWith(isListening: listening);
  }

  /// Delete AI model file and reset LLM state.
  Future<void> deleteModel() async {
    await _llmService.deleteModel();
  }

  /// Sends the prompt to LlmService, dynamically building and injecting context.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isGenerating) return;

    final userMsg = AiChatMessage(
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<AiChatMessage>.from(state.messages)..add(userMsg);

    state = state.copyWith(
      messages: updatedMessages,
      isGenerating: true,
    );

    // Retrieve database context parameters asynchronously
    final fuelRemaining = await _ref.read(fuelRemainingProvider.future).catchError((_) => 0.0);
    final estimatedRange = await _ref.read(estimatedRangeProvider.future).catchError((_) => 0.0);
    final avgMileage = await _ref.read(averageMileageProvider.future).catchError((_) => 40.0);

    final trips = await _ref.read(allTripsProvider.future).catchError((_) => <Trip>[]);
    final refills = await _ref.read(allFuelEntriesProvider.future).catchError((_) => <FuelEntry>[]);
    final profile = await _ref.read(vehicleProfileProvider.future).catchError((_) => null);

    final recentTripsJson = trips.map((t) => t.toJson()).toList();
    final recentRefillsJson = refills.map((f) => f.toJson()).toList();
    final vehicleName = profile?.name ?? 'Activa';

    final botPlaceholder = AiChatMessage(
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: List<AiChatMessage>.from(state.messages)..add(botPlaceholder),
    );

    final StringBuffer tokenBuffer = StringBuffer();

    try {
      final tokenStream = _llmService.prompt(
        text.trim(),
        fuelRemaining: fuelRemaining,
        estimatedRange: estimatedRange,
        avgMileage: avgMileage,
        recentTrips: recentTripsJson,
        recentRefills: recentRefillsJson,
        vehicleName: vehicleName,
      );

      await for (final token in tokenStream) {
        tokenBuffer.write(token);

        final msgs = List<AiChatMessage>.from(state.messages);
        if (msgs.isNotEmpty) {
          msgs[msgs.length - 1] = AiChatMessage(
            text: tokenBuffer.toString(),
            isUser: false,
            timestamp: msgs.last.timestamp,
          );
          state = state.copyWith(messages: msgs);
        }
      }
    } catch (e) {
      tokenBuffer.write("\n\n*Error: Failed to fetch AI response.*");
      final msgs = List<AiChatMessage>.from(state.messages);
      if (msgs.isNotEmpty) {
        msgs[msgs.length - 1] = AiChatMessage(
          text: tokenBuffer.toString(),
          isUser: false,
          timestamp: msgs.last.timestamp,
        );
        state = state.copyWith(messages: msgs);
      }
    } finally {
      state = state.copyWith(isGenerating: false);
    }
  }

  /// Wipes active chat bubble log.
  void clearChat() {
    state = state.copyWith(messages: []);
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _progressSub?.cancel();
    super.dispose();
  }
}
