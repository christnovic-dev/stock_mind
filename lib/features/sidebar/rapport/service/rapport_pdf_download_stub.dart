import 'dart:typed_data';

import 'package:printing/printing.dart';

Future<void> downloadPdf(Uint8List bytes, String fileName) async {
  await Printing.sharePdf(bytes: bytes, filename: fileName);
}
