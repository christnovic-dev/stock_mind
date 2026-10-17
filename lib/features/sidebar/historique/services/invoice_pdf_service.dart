import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvoicePdfService {
  InvoicePdfService._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  static String _text(dynamic value, [String fallback = '—']) {
    if (value == null) return fallback;
    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  static double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _money(dynamic value) {
    return '${_number(value).toStringAsFixed(2)} DT';
  }

  static String _date(dynamic value) {
    if (value == null) return '—';

    final date = DateTime.tryParse(value.toString())?.toLocal();
    if (date == null) return '—';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  static Future<void> printInvoice({
    required String invoiceId,
    required String businessId,
  }) async {
    final id = invoiceId.trim();
    final companyId = businessId.trim();

    if (id.isEmpty || companyId.isEmpty) {
      throw Exception('Facture ou entreprise introuvable.');
    }

    // Récupérer uniquement la facture de cette entreprise.
    final invoice = await _supabase
        .from('invoices')
        .select()
        .eq('id', id)
        .eq('business_id', companyId)
        .single();

    // Récupérer les informations disponibles de l'entreprise.
    final business = await _supabase
        .from('businesses')
        .select()
        .eq('id', companyId)
        .single();

    final dynamic rawItems = invoice['items'];

    final List<Map<String, dynamic>> items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];

    final invoiceNumber = _text(invoice['invoice_number']);
    final companyName = _text(business['name'], 'Mon entreprise');

    final customerName = _text(invoice['customer_name']);
    final customerPhone = _text(invoice['customer_phone']);
    final customerCity = _text(invoice['customer_city']);
    final customerAddress = _text(invoice['customer_address']);

    final document = pw.Document();

    const navy = PdfColor.fromInt(0xFF14264B);
    const red = PdfColor.fromInt(0xFFF21D3D);
    const lightGrey = PdfColor.fromInt(0xFFF4F6FA);
    const grey = PdfColor.fromInt(0xFF6B7280);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(
            'StockMind - Document généré automatiquement',
            style: const pw.TextStyle(fontSize: 9, color: grey),
          ),
        ),
        build: (context) => [
          // En-tête
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      companyName,
                      style: pw.TextStyle(
                        fontSize: 19,
                        fontWeight: pw.FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    if (business['address'] != null)
                      pw.Text(
                        _text(business['address']),
                        style: const pw.TextStyle(fontSize: 9, color: grey),
                      ),
                    if (business['city'] != null)
                      pw.Text(
                        _text(business['city']),
                        style: const pw.TextStyle(fontSize: 9, color: grey),
                      ),
                    if (business['phone'] != null)
                      pw.Text(
                        'Tél. : ${_text(business['phone'])}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    if (business['email'] != null)
                      pw.Text(
                        _text(business['email']),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: const pw.BoxDecoration(
                  color: navy,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'FACTURE',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      invoiceNumber,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Date : ${_date(invoice['issued_at'])}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 28),
          pw.Container(height: 3, color: red),
          pw.SizedBox(height: 24),

          // Informations client
          pw.Text(
            'FACTURÉ À',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: red,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            customerName,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: navy,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Téléphone : $customerPhone',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Ville : $customerCity',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Adresse : $customerAddress',
            style: const pw.TextStyle(fontSize: 10),
          ),

          pw.SizedBox(height: 24),

          // Tableau des articles
          pw.TableHelper.fromTextArray(
            headers: ['Désignation', 'Qté', 'Prix unitaire', 'Total'],
            data: items.map((item) {
              final quantity = _number(item['quantity']);
              final unitPrice = _number(item['unit_price']);

              final subtotal = item['subtotal'] == null
                  ? quantity * unitPrice
                  : _number(item['subtotal']);

              return [
                _text(item['product_name']),
                quantity.toStringAsFixed(
                  quantity.truncateToDouble() == quantity ? 0 : 2,
                ),
                _money(unitPrice),
                _money(subtotal),
              ];
            }).toList(),
            headerDecoration: const pw.BoxDecoration(color: navy),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.all(8),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            oddRowDecoration: const pw.BoxDecoration(color: lightGrey),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(0.8),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
            },
          ),

          pw.SizedBox(height: 24),

          // Total
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 220,
              padding: const pw.EdgeInsets.all(14),
              decoration: const pw.BoxDecoration(
                color: lightGrey,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL À PAYER',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: navy,
                    ),
                  ),
                  pw.Text(
                    _money(invoice['total_amount']),
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: red,
                    ),
                  ),
                ],
              ),
            ),
          ),

          pw.SizedBox(height: 36),
          pw.Text(
            'Merci pour votre confiance.',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: navy,
            ),
          ),
        ],
      ),
    );

    // Ouvre l'aperçu d'impression.
    // Le navigateur permet ensuite d'imprimer ou
    // d'enregistrer le document en PDF.
    await Printing.layoutPdf(
      onLayout: (format) async => document.save(),
      name: '$invoiceNumber.pdf',
    );
  }
}
