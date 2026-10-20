import 'dart:html' as html;
import 'dart:typed_data';

Future<void> downloadPdf(Uint8List bytes, String fileName) async {
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
    // Laisse au navigateur le temps de démarrer le téléchargement.
    await Future<void>.delayed(const Duration(seconds: 1));
    html.Url.revokeObjectUrl(url);
  }
}
