import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/core/utils/app_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppPathProvider Tests', () {
    test('getSafeTempDirectory returns an existing directory without crashing', () async {
      final Directory dir = await AppPathProvider.getSafeTempDirectory();
      expect(dir, isNotNull);
      expect(await dir.exists(), isTrue);
    });

    test('getSafeDocumentsDirectory returns an existing directory without crashing', () async {
      final Directory dir = await AppPathProvider.getSafeDocumentsDirectory();
      expect(dir, isNotNull);
      expect(await dir.exists(), isTrue);
    });

    test('getSafeExportDirectory returns an existing directory without crashing', () async {
      final Directory dir = await AppPathProvider.getSafeExportDirectory();
      expect(dir, isNotNull);
      expect(await dir.exists(), isTrue);
      expect(dir.path.contains('Movies/Clipax') || await dir.exists(), isTrue);
    });
  });
}
