import 'dart:convert';
import 'package:starter/business_logic/models/currency.dart';
import 'package:starter/business_logic/models/rate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'storage_service.dart';

// This class is the concrete implementation of [StorageService]. Internally
// it uses shared preferences to save and retrieve data, but that is an
// implementation detail that no other class in the app knows about. Swapping
// out shared preferences with a SQL database would be as simple as creating
// a new [StorageService] implementation.
class StorageServiceImpl implements StorageService {
  static const sharedPrefExchangeRateKey = 'exchange_rate_key';
  static const sharedPrefCurrencyKey = 'currency_key';
  static const sharedPrefLastCacheTimeKey = 'cache_time_key';

  @override
  Future<List<Rate>> getExchangeRateData() async {
    String data = await _getStringFromPreferences(sharedPrefExchangeRateKey);
    List<Rate> rates = _deserializeRates(data);
    return Future<List<Rate>>.value(rates);
  }

  @override
  Future<void> cacheExchangeRateData(List<Rate> data) async {
    String jsonString = jsonEncode(data);
    await _saveToPreferences(sharedPrefExchangeRateKey, jsonString);
    await _resetCacheTimeToNow();
  }

  @override
  Future<List<Currency>> getFavoriteCurrencies() async {
    String data = await _getStringFromPreferences(sharedPrefCurrencyKey);
    if (data == '') {
      return [];
    }
    return _deserializeCurrencies(data);
  }

  @override
  Future<void> saveFavoriteCurrencies(List<Currency> data) {
    String jsonString = _serializeCurrencies(data);
    return _saveToPreferences(sharedPrefCurrencyKey, jsonString);
  }

  @override
  Future<bool> isExpiredCache() async {
    final now = DateTime.now();
    DateTime lastUpdate = await _getLastRatesCacheTime();
    Duration difference = now.difference(lastUpdate);
    return difference.inDays > 1;
  }

  List<Rate> _deserializeRates(String data) {
    List<dynamic> rateList = jsonDecode(data);
    return rateList.map<Rate>((rateMap) {
      return Rate.fromJson(rateMap as Map<String, dynamic>);
    }).toList();
  }

  List<Currency> _deserializeCurrencies(String data) {
    final codeList = jsonDecode(data);
    List<Currency> list = [];
    for (String code in codeList) {
      list.add(Currency(code));
    }
    return list;
  }

  String _serializeCurrencies(List<Currency> data) {
    final currencies = data.map((currency) => currency.isoCode).toList();
    return jsonEncode(currencies);
  }

  Future<void> _saveToPreferences(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

  Future<String> _getStringFromPreferences(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return Future<String>.value(prefs.getString(key) ?? '');
  }

  Future<void> _resetCacheTimeToNow() async {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(sharedPrefLastCacheTimeKey, timestamp);
  }

  Future<DateTime> _getLastRatesCacheTime() async {
    final prefs = await SharedPreferences.getInstance();
    int timestamp = prefs.getInt(sharedPrefLastCacheTimeKey) ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
}
