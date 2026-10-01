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

enum FontDownloadErrorType {
  none,
  noInternet,
  diskStorageError,
  downloadFailed,
  alreadyDownloading,
}

class FontDownloadResult {
  final bool success;
  final FontDownloadErrorType errorType;
  final String message;

  const FontDownloadResult({
    required this.success,
    this.errorType = FontDownloadErrorType.none,
    this.message = '',
  });

  static const FontDownloadResult ok = FontDownloadResult(success: true);
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
        name: 'Dancing Script',
        fontFamily: 'DancingScript',
        fileName: 'DancingScript-Regular.ttf',
        defaultWeight: FontWeight.w700,
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/dancingscript/DancingScript%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/dancingscript/DancingScript%5Bwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Great Vibes',
        fontFamily: 'GreatVibes',
        fileName: 'GreatVibes-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/greatvibes/GreatVibes-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/greatvibes/GreatVibes-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Pacifico',
        fontFamily: 'Pacifico',
        fileName: 'Pacifico-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/pacifico/Pacifico-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/pacifico/Pacifico-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Lobster',
        fontFamily: 'Lobster',
        fileName: 'Lobster-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/lobster/Lobster-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/lobster/Lobster-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Satisfy',
        fontFamily: 'Satisfy',
        fileName: 'Satisfy-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/apache/satisfy/Satisfy-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/apache/satisfy/Satisfy-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Parisienne',
        fontFamily: 'Parisienne',
        fileName: 'Parisienne-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/parisienne/Parisienne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/parisienne/Parisienne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Pinyon Script',
        fontFamily: 'PinyonScript',
        fileName: 'PinyonScript-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/pinyonscript/PinyonScript-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/pinyonscript/PinyonScript-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Grand Hotel',
        fontFamily: 'GrandHotel',
        fileName: 'GrandHotel-Regular.ttf',
        defaultWeight: FontWeight.w600,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/grandhotel/GrandHotel-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/grandhotel/GrandHotel-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Kaushan Script',
        fontFamily: 'KaushanScript',
        fileName: 'KaushanScript-Regular.ttf',
        defaultWeight: FontWeight.w600,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/kaushanscript/KaushanScript-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/kaushanscript/KaushanScript-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Sacramento',
        fontFamily: 'Sacramento',
        fileName: 'Sacramento-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/sacramento/Sacramento-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/sacramento/Sacramento-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Allura',
        fontFamily: 'Allura',
        fileName: 'Allura-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/allura/Allura-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/allura/Allura-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Italianno',
        fontFamily: 'Italianno',
        fileName: 'Italianno-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/italianno/Italianno-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/italianno/Italianno-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Tangerine',
        fontFamily: 'Tangerine',
        fileName: 'Tangerine-Bold.ttf',
        defaultWeight: FontWeight.bold,
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/tangerine/Tangerine-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/tangerine/Tangerine-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Courgette',
        fontFamily: 'Courgette',
        fileName: 'Courgette-Regular.ttf',
        defaultWeight: FontWeight.w600,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/courgette/Courgette-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/courgette/Courgette-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Yellowtail',
        fontFamily: 'Yellowtail',
        fileName: 'Yellowtail-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/apache/yellowtail/Yellowtail-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/apache/yellowtail/Yellowtail-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Damion',
        fontFamily: 'Damion',
        fileName: 'Damion-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/damion/Damion-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/damion/Damion-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Cookie',
        fontFamily: 'Cookie',
        fileName: 'Cookie-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/cookie/Cookie-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/cookie/Cookie-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Norican',
        fontFamily: 'Norican',
        fileName: 'Norican-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/norican/Norican-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/norican/Norican-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Berkshire Swash',
        fontFamily: 'BerkshireSwash',
        fileName: 'BerkshireSwash-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/berkshireswash/BerkshireSwash-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/berkshireswash/BerkshireSwash-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Marck Script',
        fontFamily: 'MarckScript',
        fileName: 'MarckScript-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/marckscript/MarckScript-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/marckscript/MarckScript-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Bad Script',
        fontFamily: 'BadScript',
        fileName: 'BadScript-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/badscript/BadScript-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/badscript/BadScript-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Stalemate',
        fontFamily: 'Stalemate',
        fileName: 'Stalemate-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/stalemate/Stalemate-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/stalemate/Stalemate-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Vibes',
        fontFamily: 'Vibes',
        fileName: 'Vibes-Regular.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/vibes/Vibes-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/vibes/Vibes-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rouge Script',
        fontFamily: 'RougeScript',
        fileName: 'RougeScript-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rougescript/RougeScript-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rougescript/RougeScript-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rochester',
        fontFamily: 'Rochester',
        fileName: 'Rochester-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/apache/rochester/Rochester-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/apache/rochester/Rochester-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Ruthie',
        fontFamily: 'Ruthie',
        fileName: 'Ruthie-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/ruthie/Ruthie-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/ruthie/Ruthie-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Sail',
        fontFamily: 'Sail',
        fileName: 'Sail-Regular.ttf',
        defaultWeight: FontWeight.w600,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/sail/Sail-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/sail/Sail-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Sevillana',
        fontFamily: 'Sevillana',
        fileName: 'Sevillana-Regular.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/sevillana/Sevillana-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/sevillana/Sevillana-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Yesteryear',
        fontFamily: 'Yesteryear',
        fileName: 'Yesteryear-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/yesteryear/Yesteryear-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/yesteryear/Yesteryear-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Oleo Script',
        fontFamily: 'OleoScript',
        fileName: 'OleoScript-Bold.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/oleoscript/OleoScript-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/oleoscript/OleoScript-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Oleo Script Swash',
        fontFamily: 'OleoScriptSwashCaps',
        fileName: 'OleoScriptSwashCaps-Bold.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/oleoscriptswashcaps/OleoScriptSwashCaps-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/oleoscriptswashcaps/OleoScriptSwashCaps-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Ruge Boogie',
        fontFamily: 'RugeBoogie',
        fileName: 'RugeBoogie-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rugeboogie/RugeBoogie-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rugeboogie/RugeBoogie-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Caramel',
        fontFamily: 'Caramel',
        fileName: 'Caramel-Regular.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/caramel/Caramel-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/caramel/Caramel-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Cherry Swash',
        fontFamily: 'CherrySwash',
        fileName: 'CherrySwash-Bold.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/cherryswash/CherrySwash-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/cherryswash/CherrySwash-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Dynalight',
        fontFamily: 'Dynalight',
        fileName: 'Dynalight-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/dynalight/Dynalight-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/dynalight/Dynalight-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Engagement',
        fontFamily: 'Engagement',
        fileName: 'Engagement-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/engagement/Engagement-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/engagement/Engagement-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Galada',
        fontFamily: 'Galada',
        fileName: 'Galada-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/galada/Galada-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/galada/Galada-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Julee',
        fontFamily: 'Julee',
        fileName: 'Julee-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/julee/Julee-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/julee/Julee-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Kavivanar',
        fontFamily: 'Kavivanar',
        fileName: 'Kavivanar-Regular.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/kavivanar/Kavivanar-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/kavivanar/Kavivanar-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Praise',
        fontFamily: 'Praise',
        fileName: 'Praise-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/praise/Praise-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/praise/Praise-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Charmonman',
        fontFamily: 'Charmonman',
        fileName: 'Charmonman-Bold.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/charmonman/Charmonman-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/charmonman/Charmonman-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Permanent Marker',
        fontFamily: 'PermanentMarker',
        fileName: 'PermanentMarker-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/apache/permanentmarker/PermanentMarker-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/apache/permanentmarker/PermanentMarker-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rock Salt',
        fontFamily: 'RockSalt',
        fileName: 'RockSalt-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/apache/rocksalt/RockSalt-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/apache/rocksalt/RockSalt-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Indie Flower',
        fontFamily: 'IndieFlower',
        fileName: 'IndieFlower-Regular.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/indieflower/IndieFlower-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/indieflower/IndieFlower-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Caveat',
        fontFamily: 'Caveat',
        fileName: 'Caveat-Regular.ttf',
        defaultWeight: FontWeight.w700,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/caveat/Caveat%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/caveat/Caveat%5Bwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Caveat Brush',
        fontFamily: 'CaveatBrush',
        fileName: 'CaveatBrush-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/caveatbrush/CaveatBrush-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/caveatbrush/CaveatBrush-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Kalam',
        fontFamily: 'Kalam',
        fileName: 'Kalam-Bold.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/kalam/Kalam-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/kalam/Kalam-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Patrick Hand',
        fontFamily: 'PatrickHand',
        fileName: 'PatrickHand-Regular.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/patrickhand/PatrickHand-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/patrickhand/PatrickHand-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Shadows Into Light',
        fontFamily: 'ShadowsIntoLight',
        fileName: 'ShadowsIntoLight.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/shadowsintolight/ShadowsIntoLight.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/shadowsintolight/ShadowsIntoLight.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Homemade Apple',
        fontFamily: 'HomemadeApple',
        fileName: 'HomemadeApple-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/apache/homemadeapple/HomemadeApple-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/apache/homemadeapple/HomemadeApple-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Reenie Beanie',
        fontFamily: 'ReenieBeanie',
        fileName: 'ReenieBeanie.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/reeniebeanie/ReenieBeanie.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/reeniebeanie/ReenieBeanie.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Architects Daughter',
        fontFamily: 'ArchitectsDaughter',
        fileName: 'ArchitectsDaughter-Regular.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/architectsdaughter/ArchitectsDaughter-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/architectsdaughter/ArchitectsDaughter-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Covered By Your Grace',
        fontFamily: 'CoveredByYourGrace',
        fileName: 'CoveredByYourGrace.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/coveredbyyourgrace/CoveredByYourGrace.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/coveredbyyourgrace/CoveredByYourGrace.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Walter Turncoat',
        fontFamily: 'WalterTurncoat',
        fileName: 'WalterTurncoat-Regular.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/apache/walterturncoat/WalterTurncoat-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/apache/walterturncoat/WalterTurncoat-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Kranky',
        fontFamily: 'Kranky',
        fileName: 'Kranky-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/apache/kranky/Kranky-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/apache/kranky/Kranky-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Zeyada',
        fontFamily: 'Zeyada',
        fileName: 'Zeyada.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/zeyada/Zeyada.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/zeyada/Zeyada.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Mountains of Christmas',
        fontFamily: 'MountainsofChristmas',
        fileName: 'MountainsofChristmas-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/apache/mountainsofchristmas/MountainsofChristmas-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/apache/mountainsofchristmas/MountainsofChristmas-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Amatic SC',
        fontFamily: 'AmaticSC',
        fileName: 'AmaticSC-Bold.ttf',
        defaultWeight: FontWeight.bold,
        defaultLetterSpacing: 2.0,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/amaticsc/AmaticSC-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/amaticsc/AmaticSC-Bold.ttf',
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
        name: 'Henny Penny',
        fontFamily: 'HennyPenny',
        fileName: 'HennyPenny-Regular.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/hennypenny/HennyPenny-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/hennypenny/HennyPenny-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'The Girl Next Door',
        fontFamily: 'TheGirlNextDoor',
        fileName: 'TheGirlNextDoor.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/thegirlnextdoor/TheGirlNextDoor.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/thegirlnextdoor/TheGirlNextDoor.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Sunshiney',
        fontFamily: 'Sunshiney',
        fileName: 'Sunshiney-Regular.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/apache/sunshiney/Sunshiney-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/apache/sunshiney/Sunshiney-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Love Ya Like A Sister',
        fontFamily: 'LoveYaLikeASister',
        fileName: 'LoveYaLikeASister.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/loveyalikeasister/LoveYaLikeASister.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/loveyalikeasister/LoveYaLikeASister.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Cabin Sketch',
        fontFamily: 'CabinSketch',
        fileName: 'CabinSketch-Bold.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/cabinsketch/CabinSketch-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/cabinsketch/CabinSketch-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Gaegu',
        fontFamily: 'Gaegu',
        fileName: 'Gaegu-Bold.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/gaegu/Gaegu-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/gaegu/Gaegu-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Gamja Flower',
        fontFamily: 'GamjaFlower',
        fileName: 'GamjaFlower-Regular.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/gamjaflower/GamjaFlower-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/gamjaflower/GamjaFlower-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Hi Melody',
        fontFamily: 'HiMelody',
        fileName: 'HiMelody-Regular.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/himelody/HiMelody-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/himelody/HiMelody-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Hachi Maru Pop',
        fontFamily: 'HachiMaruPop',
        fileName: 'HachiMaruPop-Regular.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/hachimarupop/HachiMaruPop-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/hachimarupop/HachiMaruPop-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Grandstander',
        fontFamily: 'Grandstander',
        fileName: 'Grandstander-Regular.ttf',
        defaultWeight: FontWeight.w700,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/grandstander/Grandstander%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/grandstander/Grandstander%5Bwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Gluten',
        fontFamily: 'Gluten',
        fileName: 'Gluten-Regular.ttf',
        defaultWeight: FontWeight.w800,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/gluten/Gluten%5Bslnt%2Cwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/gluten/Gluten%5Bslnt%2Cwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Jua',
        fontFamily: 'Jua',
        fileName: 'Jua-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/jua/Jua-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/jua/Jua-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Kirang Haerang',
        fontFamily: 'KirangHaerang',
        fileName: 'KirangHaerang-Regular.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/kiranghaerang/KirangHaerang-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/kiranghaerang/KirangHaerang-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Pangolin',
        fontFamily: 'Pangolin',
        fileName: 'Pangolin-Regular.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/pangolin/Pangolin-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/pangolin/Pangolin-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Mali',
        fontFamily: 'Mali',
        fileName: 'Mali-Bold.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/mali/Mali-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/mali/Mali-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Gochi Hand',
        fontFamily: 'GochiHand',
        fileName: 'GochiHand-Regular.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/gochihand/GochiHand-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/gochihand/GochiHand-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Bebas Neue',
        fontFamily: 'BebasNeue',
        fileName: 'BebasNeue-Regular.ttf',
        defaultWeight: FontWeight.w900,
        defaultLetterSpacing: 1.5,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/bebasneue/BebasNeue-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/bebasneue/BebasNeue-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Anton',
        fontFamily: 'Anton',
        fileName: 'Anton-Regular.ttf',
        defaultWeight: FontWeight.w900,
        defaultLetterSpacing: 0.5,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/anton/Anton-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/anton/Anton-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Oswald',
        fontFamily: 'Oswald',
        fileName: 'Oswald-Regular.ttf',
        defaultWeight: FontWeight.w700,
        defaultLetterSpacing: 1.0,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/oswald/Oswald%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/oswald/Oswald%5Bwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Alfa Slab One',
        fontFamily: 'AlfaSlabOne',
        fileName: 'AlfaSlabOne-Regular.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/alfaslabone/AlfaSlabOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/alfaslabone/AlfaSlabOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Ultra',
        fontFamily: 'Ultra',
        fileName: 'Ultra-Regular.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/apache/ultra/Ultra-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/apache/ultra/Ultra-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Black Ops One',
        fontFamily: 'BlackOpsOne',
        fileName: 'BlackOpsOne-Regular.ttf',
        defaultWeight: FontWeight.bold,
        defaultLetterSpacing: 1.0,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/blackopsone/BlackOpsOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/blackopsone/BlackOpsOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Bangers',
        fontFamily: 'Bangers',
        fileName: 'Bangers-Regular.ttf',
        defaultWeight: FontWeight.w900,
        defaultLetterSpacing: 1.0,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/bangers/Bangers-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/bangers/Bangers-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Luckiest Guy',
        fontFamily: 'LuckiestGuy',
        fileName: 'LuckiestGuy-Regular.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/apache/luckiestguy/LuckiestGuy-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/apache/luckiestguy/LuckiestGuy-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Titan One',
        fontFamily: 'TitanOne',
        fileName: 'TitanOne-Regular.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/titanone/TitanOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/titanone/TitanOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Lilita One',
        fontFamily: 'LilitaOne',
        fileName: 'LilitaOne-Regular.ttf',
        defaultWeight: FontWeight.w800,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/lilitaone/LilitaOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/lilitaone/LilitaOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rowdies',
        fontFamily: 'Rowdies',
        fileName: 'Rowdies-Bold.ttf',
        defaultWeight: FontWeight.w800,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rowdies/Rowdies-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rowdies/Rowdies-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Russo One',
        fontFamily: 'RussoOne',
        fileName: 'RussoOne-Regular.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/russoone/RussoOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/russoone/RussoOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Knewave',
        fontFamily: 'Knewave',
        fileName: 'Knewave-Regular.ttf',
        defaultWeight: FontWeight.bold,
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/knewave/Knewave-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/knewave/Knewave-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Lemon',
        fontFamily: 'Lemon',
        fileName: 'Lemon-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/lemon/Lemon-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/lemon/Lemon-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Limelight',
        fontFamily: 'Limelight',
        fileName: 'Limelight-Regular.ttf',
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/limelight/Limelight-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/limelight/Limelight-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Londrina Solid',
        fontFamily: 'LondrinaSolid',
        fileName: 'LondrinaSolid-Black.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/londrinasolid/LondrinaSolid-Black.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/londrinasolid/LondrinaSolid-Black.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Londrina Outline',
        fontFamily: 'LondrinaOutline',
        fileName: 'LondrinaOutline-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/londrinaoutline/LondrinaOutline-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/londrinaoutline/LondrinaOutline-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Londrina Shadow',
        fontFamily: 'LondrinaShadow',
        fileName: 'LondrinaShadow-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/londrinashadow/LondrinaShadow-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/londrinashadow/LondrinaShadow-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Londrina Sketch',
        fontFamily: 'LondrinaSketch',
        fileName: 'LondrinaSketch-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/londrinasketch/LondrinaSketch-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/londrinasketch/LondrinaSketch-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Oi',
        fontFamily: 'Oi',
        fileName: 'Oi-Regular.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/oi/Oi-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/oi/Oi-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Passion One',
        fontFamily: 'PassionOne',
        fileName: 'PassionOne-Bold.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/passionone/PassionOne-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/passionone/PassionOne-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Patua One',
        fontFamily: 'PatuaOne',
        fileName: 'PatuaOne-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/patuaone/PatuaOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/patuaone/PatuaOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Paytone One',
        fontFamily: 'PaytoneOne',
        fileName: 'PaytoneOne-Regular.ttf',
        defaultWeight: FontWeight.w800,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/paytoneone/PaytoneOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/paytoneone/PaytoneOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Peralta',
        fontFamily: 'Peralta',
        fileName: 'Peralta-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/peralta/Peralta-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/peralta/Peralta-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Piedra',
        fontFamily: 'Piedra',
        fileName: 'Piedra-Regular.ttf',
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/piedra/Piedra-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/piedra/Piedra-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Poller One',
        fontFamily: 'PollerOne',
        fileName: 'PollerOne-Regular.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/pollerone/PollerOne.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/pollerone/PollerOne.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Racing Sans One',
        fontFamily: 'RacingSansOne',
        fileName: 'RacingSansOne-Regular.ttf',
        defaultWeight: FontWeight.w900,
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/racingsansone/RacingSansOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/racingsansone/RacingSansOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rock 3D',
        fontFamily: 'Rock3D',
        fileName: 'Rock3D-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rock3d/Rock3D-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rock3d/Rock3D-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'RocknRoll One',
        fontFamily: 'RocknRollOne',
        fileName: 'RocknRollOne-Regular.ttf',
        defaultWeight: FontWeight.w700,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rocknrollone/RocknRollOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rocknrollone/RocknRollOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rozha One',
        fontFamily: 'RozhaOne',
        fileName: 'RozhaOne-Regular.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rozhaone/RozhaOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rozhaone/RozhaOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Shrikhand',
        fontFamily: 'Shrikhand',
        fileName: 'Shrikhand-Regular.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/shrikhand/Shrikhand-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/shrikhand/Shrikhand-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Modak',
        fontFamily: 'Modak',
        fileName: 'Modak-Regular.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/modak/Modak-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/modak/Modak-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Bungee',
        fontFamily: 'Bungee',
        fileName: 'Bungee-Regular.ttf',
        defaultWeight: FontWeight.w800,
        defaultLetterSpacing: 1.0,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/bungee/Bungee-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/bungee/Bungee-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Bungee Shade',
        fontFamily: 'BungeeShade',
        fileName: 'BungeeShade-Regular.ttf',
        defaultWeight: FontWeight.w800,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/bungeeshade/BungeeShade-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/bungeeshade/BungeeShade-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Bungee Inline',
        fontFamily: 'BungeeInline',
        fileName: 'BungeeInline-Regular.ttf',
        defaultWeight: FontWeight.w800,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/bungeeinline/BungeeInline-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/bungeeinline/BungeeInline-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Fugaz One',
        fontFamily: 'FugazOne',
        fileName: 'FugazOne-Regular.ttf',
        defaultWeight: FontWeight.w900,
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/fugazone/FugazOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/fugazone/FugazOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Poetsen One',
        fontFamily: 'PoetsenOne',
        fileName: 'PoetsenOne-Regular.ttf',
        defaultWeight: FontWeight.w700,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/poetsenone/PoetsenOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/poetsenone/PoetsenOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Cherry Cream Soda',
        fontFamily: 'CherryCreamSoda',
        fileName: 'CherryCreamSoda-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/apache/cherrycreamsoda/CherryCreamSoda-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/apache/cherrycreamsoda/CherryCreamSoda-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Fontdiner Swanky',
        fontFamily: 'FontdinerSwanky',
        fileName: 'FontdinerSwanky-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/apache/fontdinerswanky/FontdinerSwanky-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/apache/fontdinerswanky/FontdinerSwanky-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Gorditas',
        fontFamily: 'Gorditas',
        fileName: 'Gorditas-Bold.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/gorditas/Gorditas-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/gorditas/Gorditas-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Sniglet',
        fontFamily: 'Sniglet',
        fileName: 'Sniglet-ExtraBold.ttf',
        defaultWeight: FontWeight.w800,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/sniglet/Sniglet-ExtraBold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/sniglet/Sniglet-ExtraBold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Sonsie One',
        fontFamily: 'SonsieOne',
        fileName: 'SonsieOne-Regular.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/sonsieone/SonsieOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/sonsieone/SonsieOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Trade Winds',
        fontFamily: 'TradeWinds',
        fileName: 'TradeWinds-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/tradewinds/TradeWinds-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/tradewinds/TradeWinds-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Vast Shadow',
        fontFamily: 'VastShadow',
        fileName: 'VastShadow-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/vastshadow/VastShadow-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/vastshadow/VastShadow-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Faster One',
        fontFamily: 'FasterOne',
        fileName: 'FasterOne-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/fasterone/FasterOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/fasterone/FasterOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Ranchers',
        fontFamily: 'Ranchers',
        fileName: 'Ranchers-Regular.ttf',
        defaultWeight: FontWeight.w800,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/ranchers/Ranchers-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/ranchers/Ranchers-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rammetto One',
        fontFamily: 'RammettoOne',
        fileName: 'RammettoOne-Regular.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rammettoone/RammettoOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rammettoone/RammettoOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Chicle',
        fontFamily: 'Chicle',
        fileName: 'Chicle-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/chicle/Chicle-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/chicle/Chicle-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Carter One',
        fontFamily: 'CarterOne',
        fileName: 'CarterOne.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/carterone/CarterOne.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/carterone/CarterOne.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Chango',
        fontFamily: 'Chango',
        fileName: 'Chango-Regular.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/chango/Chango-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/chango/Chango-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Chela One',
        fontFamily: 'ChelaOne',
        fileName: 'ChelaOne-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/chelaone/ChelaOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/chelaone/ChelaOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Coiny',
        fontFamily: 'Coiny',
        fileName: 'Coiny-Regular.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/coiny/Coiny-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/coiny/Coiny-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Playfair Display',
        fontFamily: 'PlayfairDisplay',
        fileName: 'PlayfairDisplay-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/playfairdisplay/PlayfairDisplay%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/playfairdisplay/PlayfairDisplay%5Bwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Abril Fatface',
        fontFamily: 'AbrilFatface',
        fileName: 'AbrilFatface-Regular.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/abrilfatface/AbrilFatface-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/abrilfatface/AbrilFatface-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Cinzel',
        fontFamily: 'Cinzel',
        fileName: 'Cinzel-Regular.ttf',
        defaultWeight: FontWeight.bold,
        defaultLetterSpacing: 1.5,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/cinzel/Cinzel%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/cinzel/Cinzel%5Bwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Cinzel Decorative',
        fontFamily: 'CinzelDecorative',
        fileName: 'CinzelDecorative-Bold.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/cinzeldecorative/CinzelDecorative-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/cinzeldecorative/CinzelDecorative-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'DM Serif Display',
        fontFamily: 'DMSerifDisplay',
        fileName: 'DMSerifDisplay-Regular.ttf',
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/dmserifdisplay/DMSerifDisplay-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/dmserifdisplay/DMSerifDisplay-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'EB Garamond',
        fontFamily: 'EBGaramond',
        fileName: 'EBGaramond-Regular.ttf',
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/ebgaramond/EBGaramond%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/ebgaramond/EBGaramond%5Bwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Lora',
        fontFamily: 'Lora',
        fileName: 'Lora-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/lora/Lora%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/lora/Lora%5Bwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'MedievalSharp',
        fontFamily: 'MedievalSharp',
        fileName: 'MedievalSharp.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/medievalsharp/MedievalSharp.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/medievalsharp/MedievalSharp.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'UnifrakturMaguntia',
        fontFamily: 'UnifrakturMaguntia',
        fileName: 'UnifrakturMaguntia-Book.ttf',
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/unifrakturmaguntia/UnifrakturMaguntia-Book.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/unifrakturmaguntia/UnifrakturMaguntia-Book.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'UnifrakturCook',
        fontFamily: 'UnifrakturCook',
        fileName: 'UnifrakturCook-Bold.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/unifrakturcook/UnifrakturCook-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/unifrakturcook/UnifrakturCook-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Pirata One',
        fontFamily: 'PirataOne',
        fileName: 'PirataOne-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/pirataone/PirataOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/pirataone/PirataOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Almendra Display',
        fontFamily: 'AlmendraDisplay',
        fileName: 'AlmendraDisplay-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/almendradisplay/AlmendraDisplay-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/almendradisplay/AlmendraDisplay-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rye',
        fontFamily: 'Rye',
        fileName: 'Rye-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rye/Rye-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rye/Rye-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Germania One',
        fontFamily: 'GermaniaOne',
        fileName: 'GermaniaOne-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/germaniaone/GermaniaOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/germaniaone/GermaniaOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Glass Antiqua',
        fontFamily: 'GlassAntiqua',
        fileName: 'GlassAntiqua-Regular.ttf',
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/glassantiqua/GlassAntiqua-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/glassantiqua/GlassAntiqua-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Milonga',
        fontFamily: 'Milonga',
        fileName: 'Milonga-Regular.ttf',
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/milonga/Milonga-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/milonga/Milonga-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Sancreek',
        fontFamily: 'Sancreek',
        fileName: 'Sancreek-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/sancreek/Sancreek-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/sancreek/Sancreek-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Spirax',
        fontFamily: 'Spirax',
        fileName: 'Spirax-Regular.ttf',
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/spirax/Spirax-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/spirax/Spirax-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Trochut',
        fontFamily: 'Trochut',
        fileName: 'Trochut-Bold.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/trochut/Trochut-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/trochut/Trochut-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Quattrocento',
        fontFamily: 'Quattrocento',
        fileName: 'Quattrocento-Bold.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/quattrocento/Quattrocento-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/quattrocento/Quattrocento-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Radley',
        fontFamily: 'Radley',
        fileName: 'Radley-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/radley/Radley-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/radley/Radley-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Bevan',
        fontFamily: 'Bevan',
        fileName: 'Bevan-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/bevan/Bevan-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/bevan/Bevan-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Calistoga',
        fontFamily: 'Calistoga',
        fileName: 'Calistoga-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/calistoga/Calistoga-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/calistoga/Calistoga-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Corben',
        fontFamily: 'Corben',
        fileName: 'Corben-Bold.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/corben/Corben-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/corben/Corben-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Coustard',
        fontFamily: 'Coustard',
        fileName: 'Coustard-Black.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/coustard/Coustard-Black.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/coustard/Coustard-Black.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Diplomata',
        fontFamily: 'Diplomata',
        fileName: 'Diplomata-Regular.ttf',
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/diplomata/Diplomata-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/diplomata/Diplomata-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Diplomata SC',
        fontFamily: 'DiplomataSC',
        fileName: 'DiplomataSC-Regular.ttf',
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/diplomatasc/DiplomataSC-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/diplomatasc/DiplomataSC-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Ewert',
        fontFamily: 'Ewert',
        fileName: 'Ewert-Regular.ttf',
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/ewert/Ewert-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/ewert/Ewert-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Federant',
        fontFamily: 'Federant',
        fileName: 'Federant-Regular.ttf',
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/federant/Federant-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/federant/Federant-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Girassol',
        fontFamily: 'Girassol',
        fileName: 'Girassol-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/girassol/Girassol-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/girassol/Girassol-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Glegoo',
        fontFamily: 'Glegoo',
        fileName: 'Glegoo-Bold.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/glegoo/Glegoo-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/glegoo/Glegoo-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Gloock',
        fontFamily: 'Gloock',
        fileName: 'Gloock-Regular.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/gloock/Gloock-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/gloock/Gloock-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Gravitas One',
        fontFamily: 'GravitasOne',
        fileName: 'GravitasOne.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/gravitasone/GravitasOne.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/gravitasone/GravitasOne.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Grenze Gotisch',
        fontFamily: 'GrenzeGotisch',
        fileName: 'GrenzeGotisch-Regular.ttf',
        defaultWeight: FontWeight.w800,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/grenzegotisch/GrenzeGotisch%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/grenzegotisch/GrenzeGotisch%5Bwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Headland One',
        fontFamily: 'HeadlandOne',
        fileName: 'HeadlandOne-Regular.ttf',
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/headlandone/HeadlandOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/headlandone/HeadlandOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'IMFell English SC',
        fontFamily: 'IMFellEnglishSC',
        fileName: 'IMFellEnglishSC-Regular.ttf',
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/imfellenglishsc/IMFeENsc28P.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/imfellenglishsc/IMFeENsc28P.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'IMFell Double Pica',
        fontFamily: 'IMFellDoublePica',
        fileName: 'IMFellDoublePica-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/imfelldoublepica/IMFELLDoublePica-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/imfelldoublepica/IMFELLDoublePica-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Uncial Antiqua',
        fontFamily: 'UncialAntiqua',
        fileName: 'UncialAntiqua-Regular.ttf',
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/uncialantiqua/UncialAntiqua-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/uncialantiqua/UncialAntiqua-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Montserrat',
        fontFamily: 'Montserrat',
        fileName: 'Montserrat-Regular.ttf',
        defaultWeight: FontWeight.w600,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/montserrat/Montserrat%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/montserrat/Montserrat%5Bwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Poppins',
        fontFamily: 'Poppins',
        fileName: 'Poppins-Bold.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/poppins/Poppins-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/poppins/Poppins-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Raleway',
        fontFamily: 'Raleway',
        fileName: 'Raleway-Regular.ttf',
        defaultWeight: FontWeight.w500,
        defaultLetterSpacing: 1.0,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/raleway/Raleway%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/raleway/Raleway%5Bwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'League Spartan',
        fontFamily: 'LeagueSpartan',
        fileName: 'LeagueSpartan-Regular.ttf',
        defaultWeight: FontWeight.w800,
        defaultLetterSpacing: 0.5,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/leaguespartan/LeagueSpartan%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/leaguespartan/LeagueSpartan%5Bwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Quicksand',
        fontFamily: 'Quicksand',
        fileName: 'Quicksand-Regular.ttf',
        defaultWeight: FontWeight.w700,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/quicksand/Quicksand%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/quicksand/Quicksand%5Bwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Comfortaa',
        fontFamily: 'Comfortaa',
        fileName: 'Comfortaa-Regular.ttf',
        defaultWeight: FontWeight.w700,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/comfortaa/Comfortaa%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/comfortaa/Comfortaa%5Bwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Fredoka',
        fontFamily: 'Fredoka',
        fileName: 'Fredoka-Regular.ttf',
        defaultWeight: FontWeight.w600,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/fredoka/Fredoka%5Bwdth%2Cwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/fredoka/Fredoka%5Bwdth%2Cwght%5D.ttf',
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
        ],
      ),
      RuntimeFontItem(
        name: 'Questrial',
        fontFamily: 'Questrial',
        fileName: 'Questrial-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/questrial/Questrial-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/questrial/Questrial-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Alegreya Sans',
        fontFamily: 'AlegreyaSans',
        fileName: 'AlegreyaSans-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/alegreyasans/AlegreyaSans-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/alegreyasans/AlegreyaSans-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Poiret One',
        fontFamily: 'PoiretOne',
        fileName: 'PoiretOne-Regular.ttf',
        defaultLetterSpacing: 2.0,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/poiretone/PoiretOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/poiretone/PoiretOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Pompiere',
        fontFamily: 'Pompiere',
        fileName: 'Pompiere-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/pompiere/Pompiere-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/pompiere/Pompiere-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Syne',
        fontFamily: 'Syne',
        fileName: 'Syne-Regular.ttf',
        defaultWeight: FontWeight.w800,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/syne/Syne%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/syne/Syne%5Bwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Play',
        fontFamily: 'Play',
        fileName: 'Play-Bold.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/play/Play-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/play/Play-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rajdhani',
        fontFamily: 'Rajdhani',
        fileName: 'Rajdhani-Bold.ttf',
        defaultWeight: FontWeight.w700,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rajdhani/Rajdhani-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rajdhani/Rajdhani-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Aclonica',
        fontFamily: 'Aclonica',
        fileName: 'Aclonica-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/apache/aclonica/Aclonica-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/apache/aclonica/Aclonica-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Baloo 2',
        fontFamily: 'Baloo2',
        fileName: 'Baloo2-Regular.ttf',
        defaultWeight: FontWeight.w800,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/baloo2/Baloo2%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/baloo2/Baloo2%5Bwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Baumans',
        fontFamily: 'Baumans',
        fileName: 'Baumans-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/baumans/Baumans-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/baumans/Baumans-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Black Han Sans',
        fontFamily: 'BlackHanSans',
        fileName: 'BlackHanSans-Regular.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/blackhansans/BlackHanSans-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/blackhansans/BlackHanSans-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Boogaloo',
        fontFamily: 'Boogaloo',
        fileName: 'Boogaloo-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/boogaloo/Boogaloo-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/boogaloo/Boogaloo-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Cagliostro',
        fontFamily: 'Cagliostro',
        fileName: 'Cagliostro-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/cagliostro/Cagliostro-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/cagliostro/Cagliostro-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Chau Philomene One',
        fontFamily: 'ChauPhilomeneOne',
        fileName: 'ChauPhilomeneOne-Regular.ttf',
        defaultStyle: FontStyle.italic,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/chauphilomeneone/ChauPhilomeneOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/chauphilomeneone/ChauPhilomeneOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Contrail One',
        fontFamily: 'ContrailOne',
        fileName: 'ContrailOne-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/contrailone/ContrailOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/contrailone/ContrailOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Do Hyeon',
        fontFamily: 'DoHyeon',
        fileName: 'DoHyeon-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/dohyeon/DoHyeon-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/dohyeon/DoHyeon-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Flamenco',
        fontFamily: 'Flamenco',
        fileName: 'Flamenco-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/flamenco/Flamenco-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/flamenco/Flamenco-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Galindo',
        fontFamily: 'Galindo',
        fileName: 'Galindo-Regular.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/galindo/Galindo-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/galindo/Galindo-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Graduate',
        fontFamily: 'Graduate',
        fileName: 'Graduate-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/graduate/Graduate-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/graduate/Graduate-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Gruppo',
        fontFamily: 'Gruppo',
        fileName: 'Gruppo-Regular.ttf',
        defaultLetterSpacing: 2.0,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/gruppo/Gruppo-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/gruppo/Gruppo-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Hammersmith One',
        fontFamily: 'HammersmithOne',
        fileName: 'HammersmithOne-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/hammersmithone/HammersmithOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/hammersmithone/HammersmithOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Jura',
        fontFamily: 'Jura',
        fileName: 'Jura-Regular.ttf',
        defaultWeight: FontWeight.w600,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/jura/Jura%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/jura/Jura%5Bwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Righteous',
        fontFamily: 'Righteous',
        fileName: 'Righteous-Regular.ttf',
        defaultWeight: FontWeight.w700,
        defaultLetterSpacing: 0.5,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/righteous/Righteous-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/righteous/Righteous-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Press Start 2P',
        fontFamily: 'PressStart2P',
        fileName: 'PressStart2P-Regular.ttf',
        defaultLetterSpacing: 1.0,
        fallbackSystemFont: 'monospace',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/pressstart2p/PressStart2P-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/pressstart2p/PressStart2P-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Silkscreen',
        fontFamily: 'Silkscreen',
        fileName: 'Silkscreen-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'monospace',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/silkscreen/Silkscreen-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/silkscreen/Silkscreen-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'VT323',
        fontFamily: 'VT323',
        fileName: 'VT323-Regular.ttf',
        defaultLetterSpacing: 1.5,
        fallbackSystemFont: 'monospace',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/vt323/VT323-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/vt323/VT323-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Special Elite',
        fontFamily: 'SpecialElite',
        fileName: 'SpecialElite-Regular.ttf',
        fallbackSystemFont: 'monospace',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/apache/specialelite/SpecialElite-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/apache/specialelite/SpecialElite-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Monoton',
        fontFamily: 'Monoton',
        fileName: 'Monoton-Regular.ttf',
        defaultLetterSpacing: 1.0,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/monoton/Monoton-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/monoton/Monoton-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Orbitron',
        fontFamily: 'Orbitron',
        fileName: 'Orbitron-Regular.ttf',
        defaultWeight: FontWeight.w800,
        defaultLetterSpacing: 1.5,
        fallbackSystemFont: 'monospace',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/orbitron/Orbitron%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/orbitron/Orbitron%5Bwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Oxanium',
        fontFamily: 'Oxanium',
        fileName: 'Oxanium-Regular.ttf',
        defaultWeight: FontWeight.w700,
        defaultLetterSpacing: 0.5,
        fallbackSystemFont: 'monospace',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/oxanium/Oxanium%5Bwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/oxanium/Oxanium%5Bwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Audiowide',
        fontFamily: 'Audiowide',
        fileName: 'Audiowide-Regular.ttf',
        defaultWeight: FontWeight.w600,
        defaultLetterSpacing: 1.0,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/audiowide/Audiowide-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/audiowide/Audiowide-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rubik Glitch',
        fontFamily: 'RubikGlitch',
        fileName: 'RubikGlitch-Regular.ttf',
        fallbackSystemFont: 'monospace',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubikglitch/RubikGlitch-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubikglitch/RubikGlitch-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rubik Glitch Pop',
        fontFamily: 'RubikGlitchPop',
        fileName: 'RubikGlitchPop-Regular.ttf',
        fallbackSystemFont: 'monospace',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubikglitchpop/RubikGlitchPop-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubikglitchpop/RubikGlitchPop-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rubik Beastly',
        fontFamily: 'RubikBeastly',
        fileName: 'RubikBeastly-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubikbeastly/RubikBeastly-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubikbeastly/RubikBeastly-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rubik Distressed',
        fontFamily: 'RubikDistressed',
        fileName: 'RubikDistressed-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubikdistressed/RubikDistressed-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubikdistressed/RubikDistressed-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rubik Moonrocks',
        fontFamily: 'RubikMoonrocks',
        fileName: 'RubikMoonrocks-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubikmoonrocks/RubikMoonrocks-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubikmoonrocks/RubikMoonrocks-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rubik Puddles',
        fontFamily: 'RubikPuddles',
        fileName: 'RubikPuddles-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubikpuddles/RubikPuddles-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubikpuddles/RubikPuddles-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rubik Vinyl',
        fontFamily: 'RubikVinyl',
        fileName: 'RubikVinyl-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubikvinyl/RubikVinyl-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubikvinyl/RubikVinyl-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rubik Iso',
        fontFamily: 'RubikIso',
        fileName: 'RubikIso-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubikiso/RubikIso-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubikiso/RubikIso-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rubik Lines',
        fontFamily: 'RubikLines',
        fileName: 'RubikLines-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubiklines/RubikLines-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubiklines/RubikLines-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rubik Pixels',
        fontFamily: 'RubikPixels',
        fileName: 'RubikPixels-Regular.ttf',
        fallbackSystemFont: 'monospace',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubikpixels/RubikPixels-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubikpixels/RubikPixels-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rubik Microbe',
        fontFamily: 'RubikMicrobe',
        fileName: 'RubikMicrobe-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubikmicrobe/RubikMicrobe-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubikmicrobe/RubikMicrobe-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rubik Wet Paint',
        fontFamily: 'RubikWetPaint',
        fileName: 'RubikWetPaint-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubikwetpaint/RubikWetPaint-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubikwetpaint/RubikWetPaint-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rubik 80s Fade',
        fontFamily: 'Rubik80sFade',
        fileName: 'Rubik80sFade-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubik80sfade/Rubik80sFade-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubik80sfade/Rubik80sFade-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rubik Bubbles',
        fontFamily: 'RubikBubbles',
        fileName: 'RubikBubbles-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubikbubbles/RubikBubbles-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubikbubbles/RubikBubbles-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rubik Doodle Shadow',
        fontFamily: 'RubikDoodleShadow',
        fileName: 'RubikDoodleShadow-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubikdoodleshadow/RubikDoodleShadow-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubikdoodleshadow/RubikDoodleShadow-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rubik Gemstones',
        fontFamily: 'RubikGemstones',
        fileName: 'RubikGemstones-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubikgemstones/RubikGemstones-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubikgemstones/RubikGemstones-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rubik Marker Hatch',
        fontFamily: 'RubikMarkerHatch',
        fileName: 'RubikMarkerHatch-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubikmarkerhatch/RubikMarkerHatch-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubikmarkerhatch/RubikMarkerHatch-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rubik Maze',
        fontFamily: 'RubikMaze',
        fileName: 'RubikMaze-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubikmaze/RubikMaze-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubikmaze/RubikMaze-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rubik Scribble',
        fontFamily: 'RubikScribble',
        fileName: 'RubikScribble-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubikscribble/RubikScribble-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubikscribble/RubikScribble-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rubik Spray Paint',
        fontFamily: 'RubikSprayPaint',
        fileName: 'RubikSprayPaint-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubikspraypaint/RubikSprayPaint-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubikspraypaint/RubikSprayPaint-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Rubik Storm',
        fontFamily: 'RubikStorm',
        fileName: 'RubikStorm-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/rubikstorm/RubikStorm-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/rubikstorm/RubikStorm-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Neonderthaw',
        fontFamily: 'Neonderthaw',
        fileName: 'Neonderthaw-Regular.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/neonderthaw/Neonderthaw-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/neonderthaw/Neonderthaw-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Road Rage',
        fontFamily: 'RoadRage',
        fileName: 'RoadRage-Regular.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/roadrage/RoadRage-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/roadrage/RoadRage-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Revalia',
        fontFamily: 'Revalia',
        fileName: 'Revalia-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/revalia/Revalia-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/revalia/Revalia-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Quantico',
        fontFamily: 'Quantico',
        fileName: 'Quantico-Bold.ttf',
        defaultWeight: FontWeight.bold,
        defaultLetterSpacing: 1.0,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/quantico/Quantico-Bold.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/quantico/Quantico-Bold.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Lacquer',
        fontFamily: 'Lacquer',
        fileName: 'Lacquer-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/lacquer/Lacquer-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/lacquer/Lacquer-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Creepster',
        fontFamily: 'Creepster',
        fileName: 'Creepster-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/creepster/Creepster-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/creepster/Creepster-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Nosifer',
        fontFamily: 'Nosifer',
        fileName: 'Nosifer-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/nosifer/Nosifer-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/nosifer/Nosifer-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Major Mono Display',
        fontFamily: 'MajorMonoDisplay',
        fileName: 'MajorMonoDisplay-Regular.ttf',
        fallbackSystemFont: 'monospace',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/majormonodisplay/MajorMonoDisplay-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/majormonodisplay/MajorMonoDisplay-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Megrim',
        fontFamily: 'Megrim',
        fileName: 'Megrim.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/megrim/Megrim.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/megrim/Megrim.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Plaster',
        fontFamily: 'Plaster',
        fileName: 'Plaster-Regular.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/plaster/Plaster-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/plaster/Plaster-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Wallpoet',
        fontFamily: 'Wallpoet',
        fileName: 'Wallpoet-Regular.ttf',
        fallbackSystemFont: 'monospace',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/wallpoet/Wallpoet-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/wallpoet/Wallpoet-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Geostar Fill',
        fontFamily: 'GeostarFill',
        fileName: 'GeostarFill-Regular.ttf',
        fallbackSystemFont: 'monospace',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/geostarfill/GeostarFill-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/geostarfill/GeostarFill-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Kelly Slab',
        fontFamily: 'KellySlab',
        fileName: 'KellySlab-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'monospace',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/kellyslab/KellySlab-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/kellyslab/KellySlab-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Akronim',
        fontFamily: 'Akronim',
        fileName: 'Akronim-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/akronim/Akronim-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/akronim/Akronim-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Atomic Age',
        fontFamily: 'AtomicAge',
        fileName: 'AtomicAge-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/atomicage/AtomicAge-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/atomicage/AtomicAge-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Bungee Hairline',
        fontFamily: 'BungeeHairline',
        fileName: 'BungeeHairline-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/bungeehairline/BungeeHairline-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/bungeehairline/BungeeHairline-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Butcherman',
        fontFamily: 'Butcherman',
        fileName: 'Butcherman-Regular.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/butcherman/Butcherman-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/butcherman/Butcherman-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Eater',
        fontFamily: 'Eater',
        fileName: 'Eater-Regular.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/eater/Eater-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/eater/Eater-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Emblema One',
        fontFamily: 'EmblemaOne',
        fileName: 'EmblemaOne-Regular.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/emblemaone/EmblemaOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/emblemaone/EmblemaOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Fascinate',
        fontFamily: 'Fascinate',
        fileName: 'Fascinate-Regular.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/fascinate/Fascinate-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/fascinate/Fascinate-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Fascinate Inline',
        fontFamily: 'FascinateInline',
        fileName: 'FascinateInline-Regular.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/fascinateinline/FascinateInline-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/fascinateinline/FascinateInline-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Flavors',
        fontFamily: 'Flavors',
        fileName: 'Flavors-Regular.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/flavors/Flavors-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/flavors/Flavors-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Frijole',
        fontFamily: 'Frijole',
        fileName: 'Frijole-Regular.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/frijole/Frijole-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/frijole/Frijole-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Fruktur',
        fontFamily: 'Fruktur',
        fileName: 'Fruktur-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/fruktur/Fruktur-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/fruktur/Fruktur-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Iceberg',
        fontFamily: 'Iceberg',
        fileName: 'Iceberg-Regular.ttf',
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/iceberg/Iceberg-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/iceberg/Iceberg-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Iceland',
        fontFamily: 'Iceland',
        fileName: 'Iceland-Regular.ttf',
        defaultLetterSpacing: 1.0,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/iceland/Iceland-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/iceland/Iceland-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Inconsolata',
        fontFamily: 'Inconsolata',
        fileName: 'Inconsolata-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'monospace',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/inconsolata/Inconsolata%5Bwdth%2Cwght%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/inconsolata/Inconsolata%5Bwdth%2Cwght%5D.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Jacquard 12',
        fontFamily: 'Jacquard12',
        fileName: 'Jacquard12-Regular.ttf',
        fallbackSystemFont: 'monospace',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/jacquard12/Jacquard12-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/jacquard12/Jacquard12-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Jacquard 24',
        fontFamily: 'Jacquard24',
        fileName: 'Jacquard24-Regular.ttf',
        fallbackSystemFont: 'monospace',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/jacquard24/Jacquard24-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/jacquard24/Jacquard24-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Jolly Lodger',
        fontFamily: 'JollyLodger',
        fileName: 'JollyLodger-Regular.ttf',
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/jollylodger/JollyLodger-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/jollylodger/JollyLodger-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Keania One',
        fontFamily: 'KeaniaOne',
        fileName: 'KeaniaOne-Regular.ttf',
        defaultWeight: FontWeight.bold,
        fallbackSystemFont: 'cursive',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/keaniaone/KeaniaOne-Regular.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/keaniaone/KeaniaOne-Regular.ttf',
        ],
      ),
      RuntimeFontItem(
        name: 'Climate Crisis',
        fontFamily: 'ClimateCrisis',
        fileName: 'ClimateCrisis-Regular.ttf',
        defaultWeight: FontWeight.w900,
        fallbackSystemFont: 'sans-serif',
        urls: [
          'https://raw.githubusercontent.com/google/fonts/main/ofl/climatecrisis/ClimateCrisis%5BYEAR%5D.ttf',
          'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/climatecrisis/ClimateCrisis%5BYEAR%5D.ttf',
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

      // Fonts are NOT downloaded automatically at startup.
      // They only download on-demand when the user selects/taps a font or clicks Download All.
    } catch (e) {
      debugPrint('RuntimeFontService init error: $e');
    }
  }

  void _startBackgroundSync() {
    if (_isBackgroundSyncing) return;
    _isBackgroundSyncing = true;

    // Asynchronously download remaining fonts concurrently with separate requests at the same time
    Future.microtask(() async {
      try {
        final pending = _catalog
            .where((item) =>
                item.status != FontDownloadStatus.downloaded &&
                item.status != FontDownloadStatus.downloading)
            .toList();

        if (pending.isEmpty) return;

        // Check connectivity upfront before launching parallel requests
        final hasNet = await checkInternet();
        if (!hasNet) return;

        // Send multiple separate download requests at the same time in parallel
        await Future.wait(
          pending.map((item) async {
            try {
              await downloadFont(item.name, isBackground: true);
            } catch (e) {
              debugPrint('Background download failed for ${item.name}: $e');
            }
          }),
        );
      } catch (e) {
        debugPrint('Error during parallel background font sync: $e');
      } finally {
        _isBackgroundSyncing = false;
      }
    });
  }

  Future<bool> checkInternet() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return true;
    }
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {
      try {
        final result2 = await InternetAddress.lookup('github.com')
            .timeout(const Duration(seconds: 3));
        if (result2.isNotEmpty && result2[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {}

      try {
        final socket = await Socket.connect('8.8.8.8', 53,
            timeout: const Duration(seconds: 2));
        socket.destroy();
        return true;
      } catch (_) {}
    }
    return false;
  }

  Future<FontDownloadResult> downloadFontDetailed(
    String nameOrFamily, {
    bool isBackground = false,
  }) async {
    final item = _findItem(nameOrFamily);
    if (item == null) {
      return const FontDownloadResult(
        success: false,
        errorType: FontDownloadErrorType.downloadFailed,
        message: 'Font not found in catalog.',
      );
    }

    if (_loadedFamilies.contains(item.fontFamily)) {
      item.status = FontDownloadStatus.downloaded;
      return FontDownloadResult(
        success: true,
        message: 'Font "${item.name}" is already available.',
      );
    }

    if (item.status == FontDownloadStatus.downloading) {
      return FontDownloadResult(
        success: false,
        errorType: FontDownloadErrorType.alreadyDownloading,
        message: 'Font "${item.name}" is already downloading...',
      );
    }

    // 1. Check internet connectivity before starting download
    if (!isBackground) {
      final hasInternet = await checkInternet();
      if (!hasInternet) {
        item.status = FontDownloadStatus.notDownloaded;
        notifyListeners();
        return const FontDownloadResult(
          success: false,
          errorType: FontDownloadErrorType.noInternet,
          message: 'No internet connection. Please check your network to download fonts.',
        );
      }
    }

    item.status = FontDownloadStatus.downloading;
    item.progress = 0.0;
    notifyListeners();

    try {
      Directory dir;
      try {
        dir = await _getFontDir();
      } catch (e) {
        item.status = FontDownloadStatus.notDownloaded;
        notifyListeners();
        return FontDownloadResult(
          success: false,
          errorType: FontDownloadErrorType.diskStorageError,
          message: 'Disk error: Unable to access font storage directory on device ($e).',
        );
      }

      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        item.status = FontDownloadStatus.notDownloaded;
        notifyListeners();
        return FontDownloadResult(
          success: false,
          errorType: FontDownloadErrorType.downloadFailed,
          message: 'Network download simulated in test environment.',
        );
      }

      final targetFile = File('${dir.path}/${item.fileName}');
      Uint8List? downloadedBytes;
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 12);

      Future<Uint8List?> fetchBytesWithRedirects(String urlStr, int maxRedirects) async {
        if (maxRedirects <= 0) return null;
        try {
          final uri = Uri.parse(urlStr);
          final request = await client.getUrl(uri);
          request.followRedirects = false;
          request.headers.set(HttpHeaders.userAgentHeader, 'Mozilla/5.0 (Flutter)');
          final response = await request.close().timeout(const Duration(seconds: 15));

          if (response.statusCode >= 300 && response.statusCode < 400) {
            final location = response.headers.value(HttpHeaders.locationHeader);
            if (location != null && location.isNotEmpty) {
              final nextUri = uri.resolve(location).toString();
              return fetchBytesWithRedirects(nextUri, maxRedirects - 1);
            }
          }

          if (response.statusCode == 200) {
            final builder = BytesBuilder();
            await for (final chunk in response) {
              builder.add(chunk);
            }
            final bytes = builder.takeBytes();
            if (bytes.length > 500) {
              return bytes;
            }
          }
        } catch (e) {
          debugPrint('RuntimeFontService failed downloading ${item.name} from $urlStr: $e');
        }
        return null;
      }

      for (final url in item.urls) {
        downloadedBytes = await fetchBytesWithRedirects(url, 5);
        if (downloadedBytes != null) break;
      }
      client.close();

      if (downloadedBytes == null) {
        item.status = FontDownloadStatus.notDownloaded;
        notifyListeners();
        return FontDownloadResult(
          success: false,
          errorType: FontDownloadErrorType.downloadFailed,
          message: 'Could not download "${item.name}". Server unavailable or connection timed out.',
        );
      }

      // 2. Save font bytes to disk and catch any storage/disk errors
      try {
        await targetFile.writeAsBytes(downloadedBytes, flush: true);
      } on FileSystemException catch (e) {
        item.status = FontDownloadStatus.notDownloaded;
        notifyListeners();
        return FontDownloadResult(
          success: false,
          errorType: FontDownloadErrorType.diskStorageError,
          message: 'Disk error: Insufficient storage space or permission to save font (${e.message}).',
        );
      } catch (e) {
        item.status = FontDownloadStatus.notDownloaded;
        notifyListeners();
        return FontDownloadResult(
          success: false,
          errorType: FontDownloadErrorType.diskStorageError,
          message: 'Disk error: Failed saving font to storage ($e).',
        );
      }

      // 3. Register font with Flutter engine
      try {
        final fontLoader = FontLoader(item.fontFamily);
        fontLoader.addFont(Future.value(ByteData.view(downloadedBytes.buffer)));
        await fontLoader.load();

        _loadedFamilies.add(item.fontFamily);
        item.status = FontDownloadStatus.downloaded;
        notifyListeners();
        return FontDownloadResult(
          success: true,
          message: 'Downloaded & applied "${item.name}"',
        );
      } catch (e) {
        debugPrint('Failed to register FontLoader for ${item.fontFamily}: $e');
        item.status = FontDownloadStatus.notDownloaded;
        notifyListeners();
        return FontDownloadResult(
          success: false,
          errorType: FontDownloadErrorType.downloadFailed,
          message: 'Error registering font data into memory ($e).',
        );
      }
    } catch (e) {
      debugPrint('Error during downloadFont for ${item.name}: $e');
      item.status = FontDownloadStatus.notDownloaded;
      notifyListeners();
      return FontDownloadResult(
        success: false,
        errorType: FontDownloadErrorType.downloadFailed,
        message: 'Could not download "${item.name}": $e',
      );
    }
  }

  Future<bool> downloadFont(String nameOrFamily, {bool isBackground = false}) async {
    final result = await downloadFontDetailed(nameOrFamily, isBackground: isBackground);
    return result.success;
  }

  int get loadedFontsCount => _loadedFamilies.length;
  int get totalFontsCount => _catalog.length;
  bool get isBackgroundSyncing => _isBackgroundSyncing;

  Future<void> downloadAllFonts() async {
    final pending = _catalog
        .where((item) =>
            !_loadedFamilies.contains(item.fontFamily) &&
            item.status != FontDownloadStatus.downloading)
        .toList();

    if (pending.isEmpty) return;

    const concurrency = 12;
    var index = 0;

    Future<void> worker() async {
      while (true) {
        if (index >= pending.length) break;
        final currentIdx = index++;
        final item = pending[currentIdx];
        try {
          var success = await downloadFont(item.name);
          if (!success) {
            // Quick retry in case of transient socket drop
            await Future.delayed(const Duration(milliseconds: 250));
            await downloadFont(item.name);
          }
        } catch (e) {
          debugPrint('Parallel downloadAll failed for ${item.name}: $e');
        }
      }
    }

    final workers = List.generate(
      concurrency.clamp(1, pending.length),
      (_) => worker(),
    );
    await Future.wait(workers);
    notifyListeners();
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

