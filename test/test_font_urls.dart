import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/core/services/runtime_font_service.dart';

void main() {
  test('Verify 100% of all 33 font items in catalog have working download URLs', () async {
    final service = RuntimeFontService.instance;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);

    final failedFonts = <String>[];

    for (final item in service.catalog) {
      bool foundWorkingUrl = false;
      for (final url in item.urls) {
        try {
          final uri = Uri.parse(url);
          final request = await client.getUrl(uri);
          request.followRedirects = true;
          request.headers.set(HttpHeaders.userAgentHeader, 'Mozilla/5.0 (Flutter)');
          final response = await request.close().timeout(const Duration(seconds: 10));
          if (response.statusCode == 200) {
            final bytes = await response.fold<List<int>>([], (prev, elem) => prev..addAll(elem));
            if (bytes.length > 500) {
              print('OK: ${item.name} (${bytes.length} bytes)');
              foundWorkingUrl = true;
              break;
            }
          } else {
            await response.drain();
          }
        } catch (_) {}
      }

      if (!foundWorkingUrl) {
        failedFonts.add(item.name);
        print('FAIL: No working URL for ${item.name}');
      }
    }
    client.close();

    expect(failedFonts, isEmpty, reason: 'Failed fonts: $failedFonts');
  });
}
