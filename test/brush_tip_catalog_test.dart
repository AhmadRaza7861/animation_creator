import 'dart:ui' as ui;

import 'package:dummy/core/localization/translations/translations.dart';
import 'package:dummy/features/editor/presentation/screens/brush_tip_studio_screen.dart';
import 'package:dummy/package_code/paint_contents.dart';
import 'package:dummy/package_code/src/drawing_bar/brush_tip_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tip kinds are append-only (saved strokes store kind.index)', () {
    // If this fails, an enum value was inserted/reordered: existing drawings
    // would load with the wrong tip. Append new kinds at the end instead.
    expect(BrushTipKind.glyphClover.index, 88);
    expect(BrushTipKind.roundedSquare.index, 89);
    expect(BrushTipKind.heartScatter.index, 122);
  });

  test('every extra tip is listed once and has translations', () {
    final Set<BrushTipKind> kinds = <BrushTipKind>{};
    for (final BrushTipDef d in kExtraBrushTips) {
      expect(kinds.add(d.kind), isTrue, reason: '${d.kind} listed twice');
      for (final MapEntry<String, Map<String, String>> lang in allTranslations.entries) {
        expect(lang.value[d.labelKey], isNotNull,
            reason: '${d.labelKey} missing in ${lang.key}');
      }
    }
    // Every kind added after the original set is in the catalog.
    for (final BrushTipKind k in BrushTipKind.values) {
      if (k.index >= BrushTipKind.roundedSquare.index) {
        expect(kinds.contains(k), isTrue, reason: '$k not in kExtraBrushTips');
      }
    }
  });

  test('every extra tip draws a dab and a hard/soft stroke without errors', () {
    const Size size = Size(400, 200);
    for (final BrushTipDef d in kExtraBrushTips) {
      final ui.PictureRecorder rec = ui.PictureRecorder();
      final Canvas canvas = Canvas(rec, Offset.zero & size);
      TipBrush.paintDab(canvas, const Offset(50, 50), 30,
          kind: d.kind, paint: Paint()..color = Colors.black, seed: 3, index: 1);
      for (final double hardness in <double>[1.0, 0.5]) {
        final TipBrush b = TipBrush(kind: d.kind, hardness: hardness, followPath: true);
        b.paint = Paint()
          ..color = Colors.black
          ..strokeWidth = 24;
        b.startDraw(const Offset(20, 100));
        for (int i = 1; i <= 40; i++) {
          b.drawing(Offset(20 + i * 8.0, 100 + (i.isEven ? 6 : -6)));
        }
        b.draw(canvas, size, false);
        final TipBrush restored = TipBrush.fromJson(b.toJson());
        expect(restored.kind, d.kind);
      }
      rec.endRecording().dispose();
    }
  });

  test('every tip in the studio picker has a unique id (no double highlight)', () {
    final Map<String, String> seen = <String, String>{};
    for (final TipItem t in kAllTipItems) {
      expect(seen.containsKey(t.id), isFalse,
          reason: '"${t.label}" has the same id as "${seen[t.id]}"');
      seen[t.id] = t.label;
    }
    // Same label, different tip: must not be equal.
    final TipItem vectorFur = kAllTipItems.firstWhere((TipItem t) => !t.isStamp && t.label == 'Fur');
    final TipItem stampFur = kAllTipItems.firstWhere((TipItem t) => t.isStamp && t.label == 'Fur');
    expect(vectorFur == stampFur, isFalse);
  });

  test('unknown / future tip index loads as round instead of crashing', () {
    final TipBrush b = TipBrush(kind: BrushTipKind.star)..paint = Paint();
    b.startDraw(const Offset(1, 1));
    b.drawing(const Offset(20, 20));
    for (final Object? bad in <Object?>[9999, -1, null, 'x']) {
      final Map<String, dynamic> json = b.toJson()..['kind'] = bad;
      expect(TipBrush.fromJson(json).kind, BrushTipKind.round, reason: 'kind=$bad');
    }
  });

  testWidgets('every extra tip stays inside its preview tile', (WidgetTester tester) async {
    await tester.runAsync(() async {
      const double r = 40, tile = 2 * r, pad = 20, side = tile + 2 * pad;
      final List<String> clipped = <String>[];
      for (final BrushTipDef d in kExtraBrushTips) {
        final ui.PictureRecorder rec = ui.PictureRecorder();
        final Canvas c = Canvas(rec);
        // Check several random dab variants for scatter tips.
        for (int index = 0; index < 6; index++) {
          TipBrush.paintDab(c, const Offset(side / 2, side / 2), r,
              kind: d.kind, paint: Paint()..color = Colors.black, seed: 11, index: index);
        }
        final ui.Image img = await rec.endRecording().toImage(side.toInt(), side.toInt());
        final data = (await img.toByteData())!;
        int outside = 0;
        for (int y = 0; y < side; y++) {
          for (int x = 0; x < side; x++) {
            final bool inTile = x >= pad - 1 && x < pad + tile + 1 && y >= pad - 1 && y < pad + tile + 1;
            if (!inTile && data.getUint8((y * side.toInt() + x) * 4 + 3) > 40) outside++;
          }
        }
        if (outside > 0) clipped.add('${d.label} ($outside px)');
      }
      expect(clipped, isEmpty, reason: 'tips drawing outside their preview tile');
    });
  });
}
