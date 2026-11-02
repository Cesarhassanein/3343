import 'dart:html' as html;

void triggerFileDownload(String url, String fileName) {
  try {
    final anchor = html.AnchorElement(href: url)
      ..target = '_blank'
      ..download = fileName;
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
  } catch (_) {
    html.window.open(url, '_blank');
  }
}
