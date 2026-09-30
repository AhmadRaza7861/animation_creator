import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

enum FontDownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  failed,
}

class RuntimeFontItem {
  final String name;
  final String fontFamily;
  final List<String> urls;
  final String fileName;
  final FontWeight defaultWeight;
  final FontStyle defaultStyle;
  final double defaultLetterSpacing;
  final String fallbackSystemFont;

  FontDownloadStatus status;
  double progress;

  RuntimeFontItem({
    required this.name,
    required this.fontFamily,
    required this.urls,
    required this.fileName,
    this.defaultWeight = FontWeight.normal,
    this.defaultStyle = FontStyle.normal,
    this.defaultLetterSpacing = 0.0,
    this.fallbackSystemFont = 'sans-serif',
    this.status = FontDownloadStatus.notDownloaded,
    this.progress = 0.0,
  });
}

class RuntimeFontService extends ChangeNotifier {
  static final RuntimeFontService _instance = RuntimeFontService._internal();
  static RuntimeFontService get instance => _instance;

  RuntimeFontService._internal() {
    _initCatalog();
  }

  final Set<String> _loadedFamilies = <String>{};
  Directory? _fontDirectory;
  bool _isInitialized = false;
  bool _isBackgroundSyncing = false;

  late final List<RuntimeFontItem> _catalog;

  List<RuntimeFontItem> get catalog => List.unmodifiable(_catalog);

  bool isFontLoaded(String? fontFamily) {
    if (fontFamily == null || fontFamily.isEmpty || fontFamily == 'Default') {
      return true;
    }
    return _loadedFamilies.contains(fontFamily);
  }

  FontDownloadStatus getFontStatus(String nameOrFamily) {
    final item = _findItem(nameOrFamily);
    if (item == null) return FontDownloadStatus.downloaded;
    if (_loadedFamilies.contains(item.fontFamily)) {
      return FontDownloadStatus.downloaded;
    }
    return item.status;
  }

  RuntimeFontItem? _findItem(String nameOrFamily) {
    for (final item in _catalog) {
      if (item.name == nameOrFamily || item.fontFamily == nameOrFamily) {
        return item;
      }
    }
    return null;
  }

  void _initCatalog() {
    _catalog = [
      RuntimeFontItem(
        name: 'Alex Brush',
        fontFamily: 'AlexBrush',
        fileName: 'AlexBrush-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/alexbrush/AlexBrush-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/alexbrush/AlexBrush-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Art Typo',
        fontFamily: 'ArtTypo',
        fileName: 'ArtTypo.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'monospace',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubikglitch/RubikGlitch-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubikglitch/RubikGlitch-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Avara',
        fontFamily: 'Avara',
        fileName: 'Avara-Bold.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/cinzel/Cinzel%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/cinzel/Cinzel%5Bwght%5D.ttf',
          'https://raw.githubusercontent.com/google/fonts/main/ofl/cormorantgaramond/CormorantGaramond-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Battlestar',
        fontFamily: 'Battlestar',
        fileName: 'Battlestar.ttf',
        defaultWeight: FontWeight.bold,
        defaultLetterSpacing: 2.0,
        fallbackSystemFont: 'monospace',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/orbitron/Orbitron%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/orbitron/Orbitron%5Bwght%5D.ttf',
          'https://raw.githubusercontent.com/google/fonts/main/ofl/audiowide/Audiowide-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Boom Box',
        fontFamily: 'BoomBox',
        fileName: 'BoomBox.ttf',
        defaultWeight: FontWeight.w800,
        defaultLetterSpacing: 1.5,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/bungee/Bungee-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/bungee/Bungee-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Cameo Antique',
        fontFamily: 'CameoAntique',
        fileName: 'CameoAntique.ttf',
        defaultWeight: FontWeight.w600,
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/cinzeldecorative/CinzelDecorative-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/cinzeldecorative/CinzelDecorative-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Charakterny',
        fontFamily: 'Charakterny',
        fileName: 'Charakterny.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/greatvibes/GreatVibes-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/greatvibes/GreatVibes-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'ClearSans Bold',
        fontFamily: 'ClearSans-Bold',
        fileName: 'ClearSans-Bold.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/intel/clear-sans/master/TTF/ClearSans-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/intel/clear-sans@master/TTF/ClearSans-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'ClearSans Light',
        fontFamily: 'ClearSans-Light',
        fileName: 'ClearSans-Light.ttf',
        defaultWeight: FontWeight.w300,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/intel/clear-sans/master/TTF/ClearSans-Light.ttf',
          'https://cdn.jsdelivr.net/gh/intel/clear-sans@master/TTF/ClearSans-Light.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'ClearSans Regular',
        fontFamily: 'ClearSans-Regular',
        fileName: 'ClearSans-Regular.ttf',
        defaultWeight: FontWeight.normal,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/intel/clear-sans/master/TTF/ClearSans-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/intel/clear-sans@master/TTF/ClearSans-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'ComicNeue Bold',
        fontFamily: 'ComicNeue-Bold',
        fileName: 'ComicNeue-Bold.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/comicneue/ComicNeue-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/comicneue/ComicNeue-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'ComicNeue Regular',
        fontFamily: 'ComicNeue-Regular',
        fileName: 'ComicNeue-Regular.ttf',
        defaultWeight: FontWeight.normal,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/comicneue/ComicNeue-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/comicneue/ComicNeue-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Comili Book',
        fontFamily: 'ComiliBook',
        fileName: 'ComiliBook.ttf',
        defaultWeight: FontWeight.w600,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/caveat/Caveat%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/caveat/Caveat%5Bwght%5D.ttf',
          'https://raw.githubusercontent.com/google/fonts/main/ofl/kalam/Kalam-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'CooperHewitt Book',
        fontFamily: 'CooperHewittBook',
        fileName: 'CooperHewitt-Book.ttf',
        defaultWeight: FontWeight.w400,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/questrial/Questrial-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/questrial/Questrial-Regular.ttf',
          'https://raw.githubusercontent.com/google/fonts/main/ofl/alegreyasans/AlegreyaSans-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Earwig Factory',
        fontFamily: 'EarwigFactory',
        fileName: 'EarwigFactory.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'monospace',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubikmicrobe/RubikMicrobe-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubikmicrobe/RubikMicrobe-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Exo Bold',
        fontFamily: 'Exo-Bold',
        fileName: 'Exo-Bold.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/exo/Exo%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/exo/Exo%5Bwght%5D.ttf',
          'https://raw.githubusercontent.com/google/fonts/main/ofl/exo2/Exo2%5Bwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Exo Regular',
        fontFamily: 'Exo-Regular',
        fileName: 'Exo-Regular.ttf',
        defaultWeight: FontWeight.normal,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/exo/Exo%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/exo/Exo%5Bwght%5D.ttf',
          'https://raw.githubusercontent.com/google/fonts/main/ofl/exo2/Exo2%5Bwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Exo Thin',
        fontFamily: 'Exo-Thin',
        fileName: 'Exo-Thin.ttf',
        defaultWeight: FontWeight.w200,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/exo/Exo%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/exo/Exo%5Bwght%5D.ttf',
          'https://raw.githubusercontent.com/google/fonts/main/ofl/exo2/Exo2%5Bwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Garineldo',
        fontFamily: 'Garineldo',
        fileName: 'Garineldo.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/italianno/Italianno-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/italianno/Italianno-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Garineldo No1',
        fontFamily: 'GarineldoNo1',
        fileName: 'GarineldoNo1.ttf',
        defaultStyle: FontStyle.italic,
        defaultWeight: FontWeight.w600,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/tangerine/Tangerine-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/tangerine/Tangerine-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Liner',
        fontFamily: 'Liner',
        fileName: 'Liner.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/monoton/Monoton-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/monoton/Monoton-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Mathilde',
        fontFamily: 'Mathilde',
        fileName: 'Mathilde.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/allura/Allura-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/allura/Allura-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Mirage',
        fontFamily: 'Mirage',
        fileName: 'Mirage.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubikwetpaint/RubikWetPaint-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubikwetpaint/RubikWetPaint-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'New Waltograph',
        fontFamily: 'NewWaltograph',
        fileName: 'NewWaltograph.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/pacifico/Pacifico-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/pacifico/Pacifico-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'NumbBunny',
        fontFamily: 'NumbBunny',
        fileName: 'NumbBunny.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/creepster/Creepster-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/creepster/Creepster-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'PRIDA61',
        fontFamily: 'PRIDA61',
        fileName: 'PRIDA61.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/medievalsharp/MedievalSharp.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/medievalsharp/MedievalSharp.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'PRIDA65',
        fontFamily: 'PRIDA65',
        fileName: 'PRIDA65.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rye/Rye-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rye/Rye-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'RocketFuel',
        fontFamily: 'RocketFuel',
        fileName: 'RocketFuel.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/bangers/Bangers-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/bangers/Bangers-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'RocketFuel Outlined',
        fontFamily: 'RocketFuelOutlined',
        fileName: 'RocketFuelOutlined.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubikglitchpop/RubikGlitchPop-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubikglitchpop/RubikGlitchPop-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Sadegnak No1',
        fontFamily: 'SadegnakNo1',
        fileName: 'SadegnakNo1.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/nosifer/Nosifer-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/nosifer/Nosifer-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'SUPER TIKI',
        fontFamily: 'SUPERTiki',
        fileName: 'SUPERTiki.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/shrikhand/Shrikhand-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/shrikhand/Shrikhand-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'WHYPO',
        fontFamily: 'WHYPO',
        fileName: 'WHYPO.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/modak/Modak-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/modak/Modak-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Xolonium Bold',
        fontFamily: 'XoloniumBold',
        fileName: 'Xolonium-Bold.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'monospace',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/oxanium/Oxanium%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/oxanium/Oxanium%5Bwght%5D.ttf',
        ],
      ),
    ];
  }

  Future<Directory> _getFontDir() async {
    if (_fontDirectory != null) return _fontDirectory!;
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/runtime_fonts');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _fontDirectory = dir;
    return dir;
  }

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      final dir = await _getFontDir();

      // 1. Scan and instantly register any already-downloaded font files
      for (final item in _catalog) {
        final file = File('${dir.path}/${item.fileName}');
        if (await file.exists()) {
          try {
            final bytes = await file.readAsBytes();
            if (bytes.length > 500) {
              final fontLoader = FontLoader(item.fontFamily);
              fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
              await fontLoader.load();
              _loadedFamilies.add(item.fontFamily);
              item.status = FontDownloadStatus.downloaded;
            } else {
              // Corrupted or empty file, delete and redownload
              await file.delete().catchError((_) => file);
              item.status = FontDownloadStatus.notDownloaded;
            }
          } catch (e) {
            debugPrint('Error loading cached font ${item.name}: $e');
            item.status = FontDownloadStatus.notDownloaded;
          }
        } else {
          item.status = FontDownloadStatus.notDownloaded;
        }
      }
      notifyListeners();

      // 2. Start non-blocking background sync for missing fonts
      _startBackgroundSync();
    } catch (e) {
      debugPrint('RuntimeFontService init error: $e');
    }
  }

  void _startBackgroundSync() {
    if (_isBackgroundSyncing) return;
    _isBackgroundSyncing = true;

    // Asynchronously download remaining fonts in background
    Future.microtask(() async {
      try {
        final pending = _catalog
            .where((item) =>
                item.status != FontDownloadStatus.downloaded &&
                item.status != FontDownloadStatus.downloading)
            .toList();

        for (final item in pending) {
          try {
            await downloadFont(item.name, isBackground: true);
          } catch (_) {}
          // Gentle breather between background downloads
          await Future.delayed(const Duration(milliseconds: 100));
        }
      } finally {
        _isBackgroundSyncing = false;
      }
    });
  }

  Future<bool> downloadFont(String nameOrFamily, {bool isBackground = false}) async {
    final item = _findItem(nameOrFamily);
    if (item == null) return false;

    if (_loadedFamilies.contains(item.fontFamily)) {
      item.status = FontDownloadStatus.downloaded;
      return true;
    }

    if (item.status == FontDownloadStatus.downloading) {
      return false;
    }

    item.status = FontDownloadStatus.downloading;
    item.progress = 0.0;
    notifyListeners();

    try {
      final dir = await _getFontDir();
      final targetFile = File('${dir.path}/${item.fileName}');

      Uint8List? downloadedBytes;
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 12);

      for (final url in item.urls) {
        try {
          final uri = Uri.parse(url);
          final request = await client.getUrl(uri);
          request.followRedirects = true;
          request.headers.set(HttpHeaders.userAgentHeader, 'Mozilla/5.0 (Flutter)');
          final response = await request.close().timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            final builder = BytesBuilder();
            await for (final chunk in response) {
              builder.add(chunk);
            }
            final bytes = builder.takeBytes();
            if (bytes.length > 500) {
              downloadedBytes = bytes;
              break;
            }
          }
        } catch (e) {
          // Try next fallback URL in list
          debugPrint('RuntimeFontService failed downloading ${item.name} from $url: $e');
        }
      }
      client.close();

      if (downloadedBytes != null) {
        await targetFile.writeAsBytes(downloadedBytes);

        try {
          final fontLoader = FontLoader(item.fontFamily);
          fontLoader.addFont(Future.value(ByteData.view(downloadedBytes.buffer)));
          await fontLoader.load();

          _loadedFamilies.add(item.fontFamily);
          item.status = FontDownloadStatus.downloaded;
          notifyListeners();
          return true;
        } catch (e) {
          debugPrint('Failed to register FontLoader for ${item.fontFamily}: $e');
          item.status = FontDownloadStatus.failed;
          notifyListeners();
          return false;
        }
      } else {
        item.status = FontDownloadStatus.failed;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Error during downloadFont for ${item.name}: $e');
      item.status = FontDownloadStatus.failed;
      notifyListeners();
      return false;
    }
  }

  void retryAllFailed() {
    for (final item in _catalog) {
      if (item.status == FontDownloadStatus.failed ||
          item.status == FontDownloadStatus.notDownloaded) {
        item.status = FontDownloadStatus.notDownloaded;
      }
    }
    _startBackgroundSync();
  }
}
