import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_tracker_app/core/ai/llm_service.dart';

void main() {
  group('LlmService Context Injection and Mock Fallback', () {
    late LlmService service;

    setUp(() {
      service = LlmService();
    });

    test('Prompt yields streaming text in mock mode', () async {
      // By default it starts in mock mode before native init
      final stream = service.prompt(
        "range",
        fuelRemaining: 3.5,
        estimatedRange: 155.0,
        avgMileage: 44.3,
        recentTrips: [],
        recentRefills: [],
        vehicleName: "Activa 6G",
      );

      final tokens = await stream.toList();
      final fullText = tokens.join('');

      expect(fullText.contains('155.0 km'), true);
      expect(fullText.contains('3.50 L'), true);
      expect(service.isMockMode, true);
    });

    test('Prompt contains average mileage when queried', () async {
      final stream = service.prompt(
        "mileage",
        fuelRemaining: 2.0,
        estimatedRange: 90.0,
        avgMileage: 45.0,
        recentTrips: [],
        recentRefills: [],
        vehicleName: "Activa 6G",
      );

      final tokens = await stream.toList();
      final fullText = tokens.join('');

      expect(fullText.contains('45.0 km/L'), true);
    });

    test('Prompt parses recent refills correctly', () async {
      final refills = [
        {
          'litresFilled': 4.5,
          'pricePerLitre': 102.5,
          'amountPaid': 461.25,
          'calculatedMileage': 42.0,
        }
      ];

      final stream = service.prompt(
        "refill",
        fuelRemaining: 1.0,
        estimatedRange: 42.0,
        avgMileage: 42.0,
        recentTrips: [],
        recentRefills: refills,
        vehicleName: "Activa 6G",
      );

      final tokens = await stream.toList();
      final fullText = tokens.join('');

      expect(fullText.contains('4.5 L'), true);
      expect(fullText.contains('102.5'), true);
      expect(fullText.contains('461.25'), true);
      expect(fullText.contains('42.0 km/L'), true);
    });

    test('Prompt default query response', () async {
      final stream = service.prompt(
        "hello there",
        fuelRemaining: 1.2,
        estimatedRange: 50.0,
        avgMileage: 41.5,
        recentTrips: [],
        recentRefills: [],
        vehicleName: "Activa 6G",
      );

      final tokens = await stream.toList();
      final fullText = tokens.join('');

      expect(fullText.contains('Antigravity'), true);
      expect(fullText.contains('Activa 6G'), true);
    });
  });
}
