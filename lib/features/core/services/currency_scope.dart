import 'package:flutter/widgets.dart';

class CurrencyScope extends InheritedWidget {
  final String currencyCode;

  const CurrencyScope({
    super.key,
    required this.currencyCode,
    required super.child,
  });

  static CurrencyScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CurrencyScope>();

    assert(scope != null, 'CurrencyScope introuvable dans cet arbre.');
    return scope!;
  }

  @override
  bool updateShouldNotify(CurrencyScope oldWidget) {
    return currencyCode != oldWidget.currencyCode;
  }
}
