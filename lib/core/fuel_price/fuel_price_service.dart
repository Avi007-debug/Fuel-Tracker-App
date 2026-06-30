import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:shared_preferences/shared_preferences.dart';

/// Fuel price service — fetches live petrol prices from Indian fuel price websites.
/// 
/// Falls back to:
/// 1. Last known price from cache
/// 2. Manual entry by user
class FuelPriceService {
  static const _cacheKey = 'last_petrol_price';
  static const _cacheTimestampKey = 'last_petrol_price_timestamp';
  
  // Fallback sources for Indian petrol prices
  static const _priceUrls = [
    'https://www.goodreturns.in/petrol-price/bangalore',
    'https://www.bankbazaar.com/fuel-prices/petrol-price-in-bangalore.html',
  ];

  /// Fetch current petrol price (₹/L).
  /// 
  /// Returns null if fetch fails. Caller should prompt for manual entry.
  static Future<double?> fetchPetrolPrice() async {
    // Try each source until one succeeds
    for (final url in _priceUrls) {
      try {
        final price = await _fetchFromUrl(url);
        if (price != null && price > 0) {
          await _cachePrice(price);
          return price;
        }
      } catch (e) {
        // Try next source
        continue;
      }
    }

    // All sources failed — return cached price if available
    return await getCachedPrice();
  }

  /// Fetch price from a specific URL and parse HTML.
  static Future<double?> _fetchFromUrl(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return null;

    final document = html_parser.parse(response.body);
    
    // Try to find price in common patterns
    // Pattern 1: Look for price in rupee symbols or "₹" text
    final priceElements = document.querySelectorAll('span, div, td, p');
    
    for (final element in priceElements) {
      final text = element.text.trim();
      
      // Match patterns like "₹105.50", "105.50", "Rs. 105.50"
      final priceMatch = RegExp(r'(?:₹|Rs\.?\s*)?(\d{2,3}\.\d{1,2})')
          .firstMatch(text);
      
      if (priceMatch != null) {
        final priceStr = priceMatch.group(1);
        final price = double.tryParse(priceStr ?? '');
        
        // Validate: petrol price should be between ₹80 and ₹150
        if (price != null && price >= 80 && price <= 150) {
          return price;
        }
      }
    }

    return null;
  }

  /// Cache the price locally.
  static Future<void> _cachePrice(double price) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_cacheKey, price);
    await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get cached price (if less than 24 hours old).
  static Future<double?> getCachedPrice() async {
    final prefs = await SharedPreferences.getInstance();
    final price = prefs.getDouble(_cacheKey);
    final timestamp = prefs.getInt(_cacheTimestampKey);

    if (price == null || timestamp == null) return null;

    final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final age = DateTime.now().difference(cachedTime);

    // Cache valid for 24 hours
    if (age.inHours > 24) return null;

    return price;
  }

  /// Save manually entered price to cache.
  static Future<void> saveManualPrice(double price) async {
    await _cachePrice(price);
  }

  /// Check if cached price is available.
  static Future<bool> hasCachedPrice() async {
    final cached = await getCachedPrice();
    return cached != null;
  }
}
