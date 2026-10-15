import 'dart:html' as html;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RapportPdfService {
  static const PdfColor _navy = PdfColor(20 / 255, 38 / 255, 75 / 255);

  static const PdfColor _red = PdfColor(242 / 255, 29 / 255, 61 / 255);

  static const PdfColor _muted = PdfColor(123 / 255, 132 / 255, 152 / 255);

  static const PdfColor _light = PdfColor(247 / 255, 248 / 255, 252 / 255);

  static const PdfColor _green = PdfColor(33 / 255, 134 / 255, 83 / 255);

  static const PdfColor _orange = PdfColor(184 / 255, 117 / 255, 16 / 255);

  /// Télécharge directement le rapport PDF dans le navigateur.
  static Future<void> telechargerPdf({
    required String businessId,
    required String period,
  }) async {
    final result = await _genererPdf(businessId: businessId, period: period);

    final bytes = result.bytes;
    final fileName = result.fileName;

    final blob = html.Blob(<Object>[bytes], 'application/pdf');

    final url = html.Url.createObjectUrlFromBlob(blob);

    try {
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';

      html.document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();
    } finally {
      // Laisse au navigateur le temps de commencer le téléchargement.
      await Future<void>.delayed(const Duration(seconds: 1));

      html.Url.revokeObjectUrl(url);
    }
  }

  /// Ouvre la fenêtre d'impression du navigateur.
  static Future<void> exporter({
    required String businessId,
    required String period,
  }) async {
    final result = await _genererPdf(businessId: businessId, period: period);

    await Printing.layoutPdf(
      name: result.fileName,
      onLayout: (format) async => result.bytes,
    );
  }

  /// Génère le même rapport pour le téléchargement et l'impression.
  static Future<_RapportPdfResult> _genererPdf({
    required String businessId,
    required String period,
  }) async {
    if (businessId.trim().isEmpty) {
      throw Exception('Aucune entreprise sélectionnée.');
    }

    final supabase = Supabase.instance.client;

    // 1. Informations de l'entreprise.
    final business = await supabase
        .from('businesses')
        .select('name')
        .eq('id', businessId)
        .maybeSingle();

    final businessName = business?['name']?.toString() ?? 'Mon entreprise';

    // 2. Période du rapport.
    final now = DateTime.now();

    final days = switch (period) {
      '30 jours' => 30,
      '90 jours' => 90,
      _ => 7,
    };

    final cutoff = now.subtract(Duration(days: days));

    // 3. Produits de l'entreprise sélectionnée.
    final productsResponse = await supabase
        .from('products')
        .select('id, name, reference, quantity, minimum_quantity, price')
        .eq('business_id', businessId)
        .order('name');

    final products = (productsResponse as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    // 4. Mouvements de stock de la période.
    final movementsResponse = await supabase
        .from('stock_movements')
        .select(
          'product_name, movement_type, quantity, created_at, confirmed_at',
        )
        .eq('business_id', businessId)
        .gte('created_at', cutoff.toIso8601String())
        .order('created_at', ascending: false);

    final movements = (movementsResponse as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    // 5. Calcul des indicateurs.
    final productCount = products.length;

    double stockValue = 0;
    int totalUnits = 0;
    int entries = 0;
    int exits = 0;

    final alerts = <Map<String, dynamic>>[];

    for (final product in products) {
      final quantity = _toInt(product['quantity']);
      final minimum = _toInt(product['minimum_quantity']);
      final price = _toDouble(product['price']);

      stockValue += quantity * price;
      totalUnits += quantity;

      if (quantity <= minimum) {
        alerts.add(product);
      }
    }

    final topProducts = <String, int>{};

    for (final movement in movements) {
      final type = movement['movement_type']?.toString() ?? '';

      final quantity = _toInt(movement['quantity']);

      final name = movement['product_name']?.toString() ?? 'Produit inconnu';

      if (type == 'entree') {
        entries += quantity;
      } else if (type == 'sortie') {
        exits += quantity;
      }

      if (type == 'entree' || type == 'sortie') {
        topProducts[name] = (topProducts[name] ?? 0) + quantity;
      }
    }

    final rankedProducts = topProducts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final document = pw.Document(
      title: 'Rapport de stock - $businessName',
      author: 'StockMind',
      subject: 'Rapport de gestion de stock',
    );

    final generatedAt = _formatDate(now);

    // 6. Construction du rapport PDF multipage.
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 36),

        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _red, width: 2)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'STOCKMIND',
                style: pw.TextStyle(
                  color: _navy,
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'RAPPORT DE STOCK',
                style: pw.TextStyle(
                  color: _muted,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _light)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Document généré par StockMind',
                style: const pw.TextStyle(color: _muted, fontSize: 8),
              ),
              pw.Text(
                'Page ${context.pageNumber} / ${context.pagesCount}',
                style: const pw.TextStyle(color: _muted, fontSize: 8),
              ),
            ],
          ),
        ),

        build: (context) => [
          pw.SizedBox(height: 18),

          pw.Text(
            businessName,
            style: pw.TextStyle(
              fontSize: 23,
              fontWeight: pw.FontWeight.bold,
              color: _navy,
            ),
          ),

          pw.SizedBox(height: 5),

          pw.Text(
            'Rapport de gestion et de suivi du stock',
            style: const pw.TextStyle(fontSize: 11, color: _muted),
          ),

          pw.SizedBox(height: 14),

          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: const pw.BoxDecoration(color: _light),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _info('Période', period),
                _info('Généré le', generatedAt),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          _sectionTitle('1. Synthèse du stock'),

          pw.Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _metric('Nombre de produits', '$productCount', _navy),
              _metric('Unités en stock', '$totalUnits', _navy),
              _metric(
                'Valeur du stock',
                '${_formatNumber(stockValue)} DT',
                _red,
              ),
              _metric('Entrées sur la période', '$entries unités', _green),
              _metric('Sorties sur la période', '$exits unités', _orange),
              _metric('Alertes de stock', '${alerts.length}', _red),
            ],
          ),

          pw.SizedBox(height: 22),

          _sectionTitle('2. État actuel des produits'),

          if (products.isEmpty)
            _emptyMessage('Aucun produit enregistré.')
          else
            pw.TableHelper.fromTextArray(
              headers: [
                'Produit',
                'Référence',
                'Qté',
                'Seuil min.',
                'Prix unitaire',
                'Valeur',
              ],
              data: products.map((product) {
                final quantity = _toInt(product['quantity']);
                final price = _toDouble(product['price']);

                return [
                  product['name']?.toString() ?? '-',
                  product['reference']?.toString() ?? '-',
                  '$quantity',
                  '${_toInt(product['minimum_quantity'])}',
                  '${_formatNumber(price)} DT',
                  '${_formatNumber(quantity * price)} DT',
                ];
              }).toList(),
              headerDecoration: const pw.BoxDecoration(color: _navy),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.all(6),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              oddRowDecoration: const pw.BoxDecoration(color: _light),
            ),

          pw.SizedBox(height: 22),

          _sectionTitle('3. Alertes de stock'),

          if (alerts.isEmpty)
            _emptyMessage(
              'Aucune alerte : tous les produits dépassent leur seuil minimal.',
            )
          else
            pw.TableHelper.fromTextArray(
              headers: ['Produit', 'Stock actuel', 'Seuil minimal', 'État'],
              data: alerts.map((product) {
                final quantity = _toInt(product['quantity']);
                final minimum = _toInt(product['minimum_quantity']);

                return [
                  product['name']?.toString() ?? '-',
                  '$quantity',
                  '$minimum',
                  quantity == 0 ? 'Rupture' : 'Stock faible',
                ];
              }).toList(),
              headerDecoration: const pw.BoxDecoration(color: _red),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.all(6),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),

          pw.SizedBox(height: 22),

          _sectionTitle('4. Produits les plus mouvementés'),

          if (rankedProducts.isEmpty)
            _emptyMessage(
              'Aucun mouvement d’entrée ou de sortie sur cette période.',
            )
          else
            pw.TableHelper.fromTextArray(
              headers: ['Produit', 'Unités mouvementées'],
              data: rankedProducts.take(10).map((entry) {
                return [entry.key, '${entry.value}'];
              }).toList(),
              headerDecoration: const pw.BoxDecoration(color: _navy),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.all(6),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              oddRowDecoration: const pw.BoxDecoration(color: _light),
            ),

          pw.SizedBox(height: 22),

          _sectionTitle('5. Mouvements de stock'),

          if (movements.isEmpty)
            _emptyMessage('Aucun mouvement enregistré sur cette période.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Produit', 'Type', 'Quantité'],
              data: movements.take(100).map((movement) {
                final dateText = _formatDate(
                  DateTime.tryParse(
                        movement['confirmed_at']?.toString() ??
                            movement['created_at']?.toString() ??
                            '',
                      ) ??
                      now,
                );

                final type = movement['movement_type']?.toString() ?? '-';

                return [
                  dateText,
                  movement['product_name']?.toString() ?? '-',
                  type,
                  '${_toInt(movement['quantity'])}',
                ];
              }).toList(),
              headerDecoration: const pw.BoxDecoration(color: _navy),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.all(6),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              oddRowDecoration: const pw.BoxDecoration(color: _light),
            ),

          pw.SizedBox(height: 18),

          pw.Text(
            'Note : la valeur du stock correspond au prix unitaire '
            'multiplié par la quantité disponible. Les entrées et sorties '
            'reflètent les mouvements enregistrés pendant la période choisie. '
            'Les ajustements sont listés dans les mouvements, mais ne sont '
            'pas ajoutés aux totaux d’entrées ou de sorties.',
            style: const pw.TextStyle(color: _muted, fontSize: 8),
          ),
        ],
      ),
    );

    final safeName = businessName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

    final bytes = Uint8List.fromList(await document.save());

    return _RapportPdfResult(
      bytes: bytes,
      fileName: 'StockMind_Rapport_$safeName.pdf',
    );
  }

  static pw.Widget _info(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _muted)),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            color: _navy,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _metric(String label, String value, PdfColor color) {
    return pw.Container(
      width: 160,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _light,
        border: pw.Border(left: pw.BorderSide(color: color, width: 3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _muted)),
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 9),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: _navy,
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _emptyMessage(String message) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      color: _light,
      child: pw.Text(
        message,
        style: const pw.TextStyle(color: _muted, fontSize: 9),
      ),
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _formatNumber(num value) {
    final parts = value.toStringAsFixed(2).split('.');
    final integer = parts[0];
    final buffer = StringBuffer();

    for (int i = 0; i < integer.length; i++) {
      if (i > 0 && (integer.length - i) % 3 == 0) {
        buffer.write(' ');
      }

      buffer.write(integer[i]);
    }

    return '${buffer.toString()},${parts[1]}';
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}

class _RapportPdfResult {
  final Uint8List bytes;
  final String fileName;

  const _RapportPdfResult({required this.bytes, required this.fileName});
}
