import 'package:flutter/foundation.dart';
import 'package:starter/business_logic/models/currency.dart';
import 'package:starter/business_logic/models/rate.dart';
import 'package:starter/services/currency/currency_service.dart';
import 'package:starter/business_logic/utils/iso_data.dart';
import 'package:starter/services/service_locator.dart';

// This class handles the currency conversion and puts it in a form convenient
// for displaying on a view (though it known nothing about any particular view).
class CalculateScreenViewModel extends ChangeNotifier {
  final CurrencyService _currencyService = serviceLocator<CurrencyService>();

  CurrencyPresentation _baseCurrency = defaultBaseCurrency;
  List<CurrencyPresentation> _quoteCurrencies = [];
  List<Rate> _rates = [];

  static final CurrencyPresentation defaultBaseCurrency = CurrencyPresentation(
      flag: '', alphabeticCode: '', longName: '', amount: '');

  void loadData() async {
    await _loadCurrencies();
    _rates = await _currencyService.getAllExchangeRates(
        base: _baseCurrency.alphabeticCode);
    notifyListeners();
  }

  Future<void> _loadCurrencies() async {
    final currencies = await _currencyService.getFavoriteCurrencies();
    _baseCurrency = _loadBaseCurrency(currencies);
    _quoteCurrencies = _loadQuoteCurrencies(currencies);
  }

  CurrencyPresentation _loadBaseCurrency(List<Currency> currencies) {
    if (currencies.length == 0) {
      return defaultBaseCurrency;
    }
    String code = currencies[0].isoCode;
    return CurrencyPresentation(
        flag: IsoData.flagOf(code),
        alphabeticCode: code,
        longName: IsoData.longNameOf(code),
        amount: '');
  }

  List<CurrencyPresentation> _loadQuoteCurrencies(List<Currency> currencies) {
    List<CurrencyPresentation> quotes = [];
    for (int i = 1; i < currencies.length; i++) {
      String code = currencies[i].isoCode;
      quotes.add(CurrencyPresentation(
        flag: IsoData.flagOf(code),
        alphabeticCode: code,
        longName: IsoData.longNameOf(code),
        amount: currencies[i].amount.toStringAsFixed(2),
      ));
    }
    return quotes;
  }

  CurrencyPresentation get baseCurrency {
    return _baseCurrency;
  }

  List<CurrencyPresentation> get quoteCurrencies {
    return _quoteCurrencies;
  }

  void calculateExchange(String baseAmount) async {
    double amount;
    try {
      amount = double.parse(baseAmount);
    } catch (e) {
      _updateCurrenciesFor(0);
      notifyListeners();
      return null;
    }

    _updateCurrenciesFor(amount);

    notifyListeners();
  }

  void _updateCurrenciesFor(double baseAmount) {
    for (CurrencyPresentation c in _quoteCurrencies) {
      for (Rate r in _rates) {
        if (c.alphabeticCode == r.quoteCurrency) {
          c.amount = (baseAmount * r.exchangeRate).toStringAsFixed(2);
          break;
        }
      }
    }
  }

  Future refreshFavorites() async {
    await _loadCurrencies();
    notifyListeners();
  }

  Future setNewBaseCurrency(int quoteCurrencyIndex) async {
    _quoteCurrencies.add(_baseCurrency);
    _baseCurrency = _quoteCurrencies[quoteCurrencyIndex];
    _quoteCurrencies.removeAt(quoteCurrencyIndex);
    await _currencyService
        .saveFavoriteCurrencies(_convertPresentationToCurrency());
    loadData();
  }

  List<Currency> _convertPresentationToCurrency() {
    List<Currency> currencies = [];
    currencies.add(Currency(_baseCurrency.alphabeticCode));
    for (CurrencyPresentation currency in _quoteCurrencies) {
      currencies.add(Currency(currency.alphabeticCode));
    }
    return currencies;
  }
}

// A model class specifically for displaying data in a view. Everything is a
// preformatted string.
class CurrencyPresentation {
  final String flag;
  final String alphabeticCode;
  final String longName;
  String amount;

  CurrencyPresentation({
    required this.flag,
    required this.alphabeticCode,
    required this.longName,
    required this.amount,
  });
}
