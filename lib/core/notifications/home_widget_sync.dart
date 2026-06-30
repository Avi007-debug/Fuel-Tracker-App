import 'package:home_widget/home_widget.dart';

/// Helper to synchronize range and fuel data with Android/iOS home screen widgets.
class HomeWidgetSync {
  HomeWidgetSync._();

  /// Save data variables and trigger widget update broadcast.
  static Future<void> syncData({
    required double estimatedRangeKm,
    required double fuelRemainingL,
  }) async {
    try {
      await HomeWidget.saveWidgetData<double>('estimatedRange', estimatedRangeKm);
      await HomeWidget.saveWidgetData<double>('fuelRemaining', fuelRemainingL);
      await HomeWidget.updateWidget(
        name: 'HomeWidgetProvider',
        androidName: 'HomeWidgetProvider',
      );
    } catch (_) {
      // Ignored during testing or on unsupported platforms
    }
  }
}
