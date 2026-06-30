import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

enum LlmState {
  notInitialized,
  copyingFromAssets,
  initializingEngine,
  ready,
  error,
}

/// LLM service — Qwen2.5 0.5B Instruct on-device inference.
class LlmService {
  LlamaParent? _llamaParent;
  bool _isMockMode = true;
  LlmState _state = LlmState.notInitialized;
  double _copyProgress = 0.0;
  String _errorMessage = '';

  final _stateController = StreamController<LlmState>.broadcast();
  final _progressController = StreamController<double>.broadcast();

  Stream<LlmState> get stateStream => _stateController.stream;
  Stream<double> get progressStream => _progressController.stream;

  LlmState get state => _state;
  double get copyProgress => _copyProgress;
  String get errorMessage => _errorMessage;
  bool get isMockMode => _isMockMode;

  void _updateState(LlmState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Initialize the LLM: copies from assets if needed, then loads the model.
  Future<void> init() async {
    if (_state == LlmState.ready || _state == LlmState.initializingEngine || _state == LlmState.copyingFromAssets) {
      return;
    }

    try {
      final appDir = await getApplicationSupportDirectory();
      final modelsDir = Directory('${appDir.path}/models');
      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }

      final modelPath = '${modelsDir.path}/qwen2.5-0.5b-instruct-q4_k_m.gguf';
      final modelFile = File(modelPath);

      if (!await modelFile.exists()) {
        _updateState(LlmState.copyingFromAssets);
        _copyProgress = 0.0;
        _progressController.add(0.0);

        try {
          // Read asset in chunks to report copying progress
          final assetData = await rootBundle.load('assets/models/qwen2.5-0.5b-instruct-q4_k_m.gguf');
          final bytes = assetData.buffer.asUint8List();
          final totalBytes = bytes.length;

          await modelFile.create(recursive: true);
          final sink = modelFile.openWrite();
          
          const chunkSize = 1024 * 1024 * 5; // 5 MB chunks
          int written = 0;
          while (written < totalBytes) {
            final end = (written + chunkSize < totalBytes) ? written + chunkSize : totalBytes;
            sink.add(bytes.sublist(written, end));
            written = end;
            _copyProgress = written / totalBytes;
            _progressController.add(_copyProgress);
            // Yield control back to event loop
            await Future.delayed(const Duration(milliseconds: 5));
          }
          await sink.flush();
          await sink.close();
        } catch (e) {
          print("Could not copy Qwen model from assets (likely file not present yet): $e. Falling back directly to mock mode.");
          // Set to mock mode and mark ready so developer can run without copying
          _isMockMode = true;
          _updateState(LlmState.ready);
          return;
        }
      }

      _updateState(LlmState.initializingEngine);

      try {
        final loadCommand = LlamaLoad(
          path: modelPath,
          modelParams: ModelParams(),
          contextParams: ContextParams(),
          samplingParams: SamplerParams(),
        );

        _llamaParent = LlamaParent(loadCommand);
        await _llamaParent!.init();
        _isMockMode = false;
        _updateState(LlmState.ready);
      } catch (e) {
        print("Failed to initialize llama.cpp native library: $e. Falling back to mock engine.");
        _isMockMode = true;
        _updateState(LlmState.ready);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _updateState(LlmState.error);
    }
  }

  /// Delete the local model file to free up cache space.
  Future<void> deleteModel() async {
    try {
      if (_llamaParent != null) {
        _llamaParent = null;
      }
      final appDir = await getApplicationSupportDirectory();
      final modelFile = File('${appDir.path}/models/qwen2.5-0.5b-instruct-q4_k_m.gguf');
      if (await modelFile.exists()) {
        await modelFile.delete();
      }
      _isMockMode = true;
      _updateState(LlmState.notInitialized);
    } catch (e) {
      print("Error deleting model: $e");
    }
  }

  /// Send prompt to the LLM (either native or mock) and yield token stream.
  Stream<String> prompt(
    String promptText, {
    required double fuelRemaining,
    required double estimatedRange,
    required double avgMileage,
    required List<Map<String, dynamic>> recentTrips,
    required List<Map<String, dynamic>> recentRefills,
    required String vehicleName,
  }) async* {
    if (_state != LlmState.ready) {
      await init();
    }

    final contextJson = jsonEncode({
      'riderName': 'Avishkar',
      'vehicle': vehicleName,
      'fuelRemainingL': fuelRemaining,
      'estimatedRangeKm': estimatedRange,
      'averageMileageKmL': avgMileage,
      'recentTrips': recentTrips.take(5).toList(),
      'recentRefills': recentRefills.take(3).toList(),
    });

    if (_isMockMode) {
      final lowerText = promptText.toLowerCase();
      String response = '';

      if (lowerText.contains('range') || lowerText.contains('far') || lowerText.contains('distance')) {
        response = "Your estimated range is **${estimatedRange.toStringAsFixed(1)} km** with **${fuelRemaining.toStringAsFixed(2)} L** of fuel remaining. Keep riding efficiently!";
      } else if (lowerText.contains('mileage') || lowerText.contains('efficiency') || lowerText.contains('km/l')) {
        response = "Your current average mileage is **${avgMileage.toStringAsFixed(1)} km/L**. This is calculated using a rolling window of your recent refills.";
      } else if (lowerText.contains('trip') || lowerText.contains('ride')) {
        response = "You have logged **${recentTrips.length} trips** recently. Your most recent ride was a **${recentTrips.isNotEmpty ? recentTrips.first['routeType'] ?? 'custom' : 'short'}** route spanning **${recentTrips.isNotEmpty ? recentTrips.first['distanceKm'] : 0.0} km**.";
      } else if (lowerText.contains('refill') || lowerText.contains('petrol') || lowerText.contains('fill')) {
        if (recentRefills.isNotEmpty) {
          final last = recentRefills.first;
          response = "Your last refill was **${last['litresFilled']} L** of petrol at **₹${last['pricePerLitre']}/L**, costing you **₹${last['amountPaid']}**. The calculated mileage for that tank was **${last['calculatedMileage']} km/L**.";
        } else {
          response = "No recent refills logged. Go to the dashboard to log your first petrol refill!";
        }
      } else if (lowerText.contains('oil') || lowerText.contains('service')) {
        response = "Based on service intervals, you should check your engine oil levels. The standard oil interval is every **3,000 km**.";
      } else if (lowerText.contains('hello') || lowerText.contains('hi') || lowerText.contains('hey')) {
        response = "Hello Avishkar! I'm Antigravity, your Activa 6G AI companion. Ask me about your mileage, fuel levels, service reminders, or past rides!";
      } else {
        response = "I have scanned your recent logs. Your average mileage is **${avgMileage.toStringAsFixed(1)} km/L**, and you have **${estimatedRange.toStringAsFixed(1)} km** of range left. Is there a specific trip or refill detail you would like me to retrieve?";
      }

      final words = response.split(' ');
      for (var i = 0; i < words.length; i++) {
        yield words[i] + (i == words.length - 1 ? '' : ' ');
        await Future.delayed(const Duration(milliseconds: 30));
      }
    } else {
      final systemPrompt = '''
You are Antigravity, the offline smart AI assistant for Avishkar's $vehicleName.
Current vehicle diagnostics and 30-day ride data:
$contextJson

Rules:
1. Answer the user's questions about mileage, range, fuel, trips, services, or routes.
2. Keep responses highly concise (strictly under 2-3 sentences).
3. Be friendly and conversational. Formulate with clean markdown formatting.
''';

      final chatPrompt = '<|im_start|>system\n$systemPrompt<|im_end|>\n<|im_start|>user\n$promptText<|im_end|>\n<|im_start|>assistant\n';

      _llamaParent!.sendPrompt(chatPrompt);

      await for (final dynamic event in _llamaParent!.stream) {
        if (event is String) {
          yield event;
        } else {
          yield event.toString();
        }
      }
    }
  }

  void dispose() {
    _stateController.close();
    _progressController.close();
  }
}
