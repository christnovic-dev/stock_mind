class CurrencyService {
  CurrencyService._();

  static const Map<String, Map<String, String>> currencies = {
    'TND': {'name': 'Dinar tunisien', 'symbol': 'DT'},
    'USD': {'name': 'Dollar américain', 'symbol': r'$'},
    'EUR': {'name': 'Euro', 'symbol': '€'},
    'CDF': {'name': 'Franc congolais', 'symbol': 'FC'},
    'XAF': {'name': 'Franc CFA d’Afrique centrale', 'symbol': 'FCFA'},
    'XOF': {'name': 'Franc CFA d’Afrique de l’Ouest', 'symbol': 'FCFA'},
    'GBP': {'name': 'Livre sterling', 'symbol': '£'},
    'CAD': {'name': 'Dollar canadien', 'symbol': r'$ CA'},
    'CHF': {'name': 'Franc suisse', 'symbol': 'CHF'},
    'MAD': {'name': 'Dirham marocain', 'symbol': 'DH'},
    'DZD': {'name': 'Dinar algérien', 'symbol': 'DA'},
    'AED': {'name': 'Dirham des Émirats arabes unis', 'symbol': 'AED'},
    'SAR': {'name': 'Riyal saoudien', 'symbol': 'SAR'},
    'CNY': {'name': 'Yuan chinois', 'symbol': '¥'},
    'JPY': {'name': 'Yen japonais', 'symbol': '¥'},
    'ZAR': {'name': 'Rand sud-africain', 'symbol': 'R'},
    'KES': {'name': 'Shilling kényan', 'symbol': 'KSh'},
    'NGN': {'name': 'Naira nigérian', 'symbol': '₦'},
    'GHS': {'name': 'Cedi ghanéen', 'symbol': 'GH₵'},
    'BRL': {'name': 'Réal brésilien', 'symbol': 'R\$'},
  };

  static String nameOf(String? code) {
    final normalized = (code ?? 'TND').toUpperCase();
    return currencies[normalized]?['name'] ?? normalized;
  }

  static String symbolOf(String? code) {
    final normalized = (code ?? 'TND').toUpperCase();
    return currencies[normalized]?['symbol'] ?? normalized;
  }

  /// Formate un montant sans effectuer de conversion monétaire.
  ///
  /// Exemple : format(1250.5, currencyCode: 'CDF')
  /// Résultat : 1 250,50 FC
  static String format(
    num? amount, {
    String? currencyCode,
    int? decimalDigits,
  }) {
    final code = (currencyCode ?? 'TND').toUpperCase();
    final value = amount ?? 0;

    // Les devises sans subdivisions usuelles peuvent être affichées
    // sans décimales par défaut.
    final digits =
        decimalDigits ??
        (code == 'CDF' ||
                code == 'XAF' ||
                code == 'XOF' ||
                code == 'JPY' ||
                code == 'DZD'
            ? 0
            : 2);

    final fixed = value.toStringAsFixed(digits);
    final parts = fixed.split('.');
    final integerPart = parts[0];
    final negative = integerPart.startsWith('-');
    final digitsOnly = negative ? integerPart.substring(1) : integerPart;

    final grouped = digitsOnly.replaceAllMapped(
      RegExp(r'(?<=\d)(?=(\d{3})+$)'),
      (_) => ' ',
    );

    final formattedNumber =
        '${negative ? '-' : ''}$grouped'
        '${parts.length > 1 ? ',${parts[1]}' : ''}';

    return '$formattedNumber ${symbolOf(code)}';
  }
}
