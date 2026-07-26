import 'dart:math';

import 'package:flutter/painting.dart';

import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'shapes.dart';

/// 图形元件 / A primitive that makes up a figure
///
/// 所有坐标都是相对拖拽矩形的比例值（0~1），因此图形可随拖拽任意缩放。
///
/// All coordinates are fractions (0..1) of the drag rectangle, so figures scale
/// freely with the drag.
sealed class FigurePrim {
  const FigurePrim();
}

/// 折线 / 多边形 / Polyline or polygon
class PolyPrim extends FigurePrim {
  const PolyPrim(this.points, {this.closed = true});

  final List<Offset> points;
  final bool closed;
}

/// 椭圆 / Oval
class OvalPrim extends FigurePrim {
  const OvalPrim(this.rect);

  final Rect rect;
}

// ---------------------------------------------------------------------------
// 生成器 / Generators
// ---------------------------------------------------------------------------

/// 环形排列的圆形花瓣 / Round petals arranged in a ring
List<FigurePrim> _radialOvals(Offset c, double dist, double rad, int n) => <FigurePrim>[
      for (int i = 0; i < n; i++)
        OvalPrim(Rect.fromLTRB(
          c.dx + dist * cos(i * 2 * pi / n) - rad,
          c.dy + dist * sin(i * 2 * pi / n) - rad,
          c.dx + dist * cos(i * 2 * pi / n) + rad,
          c.dy + dist * sin(i * 2 * pi / n) + rad,
        )),
    ];

/// 环形排列的尖花瓣 / Pointed petals arranged in a ring
List<FigurePrim> _radialPetals(Offset c, double inner, double outer, int n, double half) =>
    <FigurePrim>[
      for (int i = 0; i < n; i++)
        PolyPrim(<Offset>[
          Offset(c.dx + inner * cos(i * 2 * pi / n - half),
              c.dy + inner * sin(i * 2 * pi / n - half)),
          Offset(c.dx + outer * cos(i * 2 * pi / n), c.dy + outer * sin(i * 2 * pi / n)),
          Offset(c.dx + inner * cos(i * 2 * pi / n + half),
              c.dy + inner * sin(i * 2 * pi / n + half)),
        ]),
    ];

/// 放射状线条（太阳光芒等）/ Radiating lines (sun rays, etc.)
List<FigurePrim> _rays(Offset c, double r0, double r1, int n) => <FigurePrim>[
      for (int i = 0; i < n; i++)
        PolyPrim(
          <Offset>[
            Offset(c.dx + r0 * cos(i * 2 * pi / n), c.dy + r0 * sin(i * 2 * pi / n)),
            Offset(c.dx + r1 * cos(i * 2 * pi / n), c.dy + r1 * sin(i * 2 * pi / n)),
          ],
          closed: false,
        ),
    ];

/// 螺旋线（玫瑰花心）/ Spiral (rose center)
PolyPrim _spiral(Offset c, double r0, double r1, double turns, int steps) => PolyPrim(
      <Offset>[
        for (int i = 0; i <= steps; i++)
          Offset(
            c.dx + (r0 + (r1 - r0) * i / steps) * cos(i / steps * turns * 2 * pi),
            c.dy + (r0 + (r1 - r0) * i / steps) * sin(i / steps * turns * 2 * pi),
          ),
      ],
      closed: false,
    );

// ---------------------------------------------------------------------------
// 图形库 / Figure library
// ---------------------------------------------------------------------------

/// 所有图形的元件定义 / Primitive definitions for every figure
final Map<String, List<FigurePrim>> kFigures = <String, List<FigurePrim>>{
  // ---- 交通工具 / Vehicles ----
  'car': <FigurePrim>[
    const PolyPrim(<Offset>[
      Offset(0.02, 0.72), Offset(0.02, 0.55), Offset(0.18, 0.55), Offset(0.30, 0.32),
      Offset(0.62, 0.32), Offset(0.74, 0.55), Offset(0.98, 0.55), Offset(0.98, 0.72),
    ]),
    const OvalPrim(Rect.fromLTRB(0.14, 0.62, 0.34, 0.88)),
    const OvalPrim(Rect.fromLTRB(0.66, 0.62, 0.86, 0.88)),
  ],
  'bus': <FigurePrim>[
    const PolyPrim(<Offset>[
      Offset(0.03, 0.18), Offset(0.97, 0.18), Offset(0.97, 0.74), Offset(0.03, 0.74),
    ]),
    const PolyPrim(<Offset>[
      Offset(0.10, 0.28), Offset(0.30, 0.28), Offset(0.30, 0.46), Offset(0.10, 0.46),
    ]),
    const PolyPrim(<Offset>[
      Offset(0.40, 0.28), Offset(0.60, 0.28), Offset(0.60, 0.46), Offset(0.40, 0.46),
    ]),
    const PolyPrim(<Offset>[
      Offset(0.70, 0.28), Offset(0.90, 0.28), Offset(0.90, 0.46), Offset(0.70, 0.46),
    ]),
    const OvalPrim(Rect.fromLTRB(0.14, 0.66, 0.32, 0.90)),
    const OvalPrim(Rect.fromLTRB(0.68, 0.66, 0.86, 0.90)),
  ],
  'truck': <FigurePrim>[
    const PolyPrim(<Offset>[
      Offset(0.03, 0.22), Offset(0.55, 0.22), Offset(0.55, 0.70), Offset(0.03, 0.70),
    ]),
    const PolyPrim(<Offset>[
      Offset(0.57, 0.40), Offset(0.76, 0.40), Offset(0.88, 0.54),
      Offset(0.88, 0.70), Offset(0.57, 0.70),
    ]),
    const OvalPrim(Rect.fromLTRB(0.10, 0.62, 0.28, 0.88)),
    const OvalPrim(Rect.fromLTRB(0.62, 0.62, 0.80, 0.88)),
  ],
  'airplane': <FigurePrim>[
    const OvalPrim(Rect.fromLTRB(0.43, 0.04, 0.57, 0.92)),
    const PolyPrim(<Offset>[
      Offset(0.45, 0.34), Offset(0.04, 0.58), Offset(0.04, 0.68), Offset(0.45, 0.54),
    ]),
    const PolyPrim(<Offset>[
      Offset(0.55, 0.34), Offset(0.96, 0.58), Offset(0.96, 0.68), Offset(0.55, 0.54),
    ]),
    const PolyPrim(<Offset>[
      Offset(0.46, 0.78), Offset(0.24, 0.90), Offset(0.24, 0.96), Offset(0.46, 0.90),
    ]),
    const PolyPrim(<Offset>[
      Offset(0.54, 0.78), Offset(0.76, 0.90), Offset(0.76, 0.96), Offset(0.54, 0.90),
    ]),
  ],
  'sailboat': <FigurePrim>[
    const PolyPrim(<Offset>[
      Offset(0.08, 0.74), Offset(0.92, 0.74), Offset(0.78, 0.94), Offset(0.22, 0.94),
    ]),
    const PolyPrim(<Offset>[Offset(0.50, 0.72), Offset(0.50, 0.06)], closed: false),
    const PolyPrim(<Offset>[Offset(0.54, 0.12), Offset(0.88, 0.68), Offset(0.54, 0.68)]),
    const PolyPrim(<Offset>[Offset(0.46, 0.20), Offset(0.16, 0.68), Offset(0.46, 0.68)]),
  ],
  'rocketShip': <FigurePrim>[
    const PolyPrim(<Offset>[
      Offset(0.50, 0.03), Offset(0.65, 0.30), Offset(0.65, 0.74),
      Offset(0.35, 0.74), Offset(0.35, 0.30),
    ]),
    const PolyPrim(<Offset>[Offset(0.35, 0.54), Offset(0.16, 0.86), Offset(0.35, 0.76)]),
    const PolyPrim(<Offset>[Offset(0.65, 0.54), Offset(0.84, 0.86), Offset(0.65, 0.76)]),
    const OvalPrim(Rect.fromLTRB(0.42, 0.34, 0.58, 0.50)),
    const PolyPrim(<Offset>[Offset(0.42, 0.76), Offset(0.50, 0.98), Offset(0.58, 0.76)]),
  ],
  'bicycle': <FigurePrim>[
    const OvalPrim(Rect.fromLTRB(0.02, 0.45, 0.42, 0.97)),
    const OvalPrim(Rect.fromLTRB(0.58, 0.45, 0.98, 0.97)),
    const PolyPrim(<Offset>[
      Offset(0.22, 0.71), Offset(0.46, 0.71), Offset(0.34, 0.36),
      Offset(0.62, 0.36), Offset(0.78, 0.71), Offset(0.46, 0.71),
    ], closed: false),
    const PolyPrim(<Offset>[Offset(0.62, 0.36), Offset(0.70, 0.26)], closed: false),
    const PolyPrim(<Offset>[Offset(0.34, 0.36), Offset(0.28, 0.28)], closed: false),
  ],

  // ---- 火柴人 / Stickman ----
  'stickStanding': <FigurePrim>[
    const OvalPrim(Rect.fromLTRB(0.38, 0.02, 0.62, 0.26)),
    const PolyPrim(<Offset>[Offset(0.50, 0.26), Offset(0.50, 0.62)], closed: false),
    const PolyPrim(<Offset>[Offset(0.26, 0.44), Offset(0.74, 0.44)], closed: false),
    const PolyPrim(<Offset>[Offset(0.50, 0.62), Offset(0.30, 0.96)], closed: false),
    const PolyPrim(<Offset>[Offset(0.50, 0.62), Offset(0.70, 0.96)], closed: false),
  ],
  'stickWalking': <FigurePrim>[
    const OvalPrim(Rect.fromLTRB(0.38, 0.02, 0.62, 0.26)),
    const PolyPrim(<Offset>[Offset(0.50, 0.26), Offset(0.50, 0.60)], closed: false),
    const PolyPrim(<Offset>[Offset(0.28, 0.52), Offset(0.50, 0.38), Offset(0.72, 0.50)],
        closed: false),
    const PolyPrim(<Offset>[
      Offset(0.26, 0.96), Offset(0.50, 0.60), Offset(0.66, 0.78), Offset(0.74, 0.96),
    ], closed: false),
  ],
  'stickRunning': <FigurePrim>[
    const OvalPrim(Rect.fromLTRB(0.44, 0.02, 0.68, 0.26)),
    const PolyPrim(<Offset>[Offset(0.56, 0.26), Offset(0.44, 0.60)], closed: false),
    const PolyPrim(<Offset>[Offset(0.22, 0.34), Offset(0.54, 0.42), Offset(0.80, 0.28)],
        closed: false),
    const PolyPrim(<Offset>[
      Offset(0.18, 0.92), Offset(0.44, 0.60), Offset(0.66, 0.72), Offset(0.84, 0.94),
    ], closed: false),
  ],
  'stickWaving': <FigurePrim>[
    const OvalPrim(Rect.fromLTRB(0.38, 0.04, 0.62, 0.28)),
    const PolyPrim(<Offset>[Offset(0.50, 0.28), Offset(0.50, 0.62)], closed: false),
    const PolyPrim(<Offset>[Offset(0.26, 0.56), Offset(0.50, 0.40), Offset(0.78, 0.14)],
        closed: false),
    const PolyPrim(<Offset>[Offset(0.50, 0.62), Offset(0.30, 0.96)], closed: false),
    const PolyPrim(<Offset>[Offset(0.50, 0.62), Offset(0.70, 0.96)], closed: false),
  ],
  'stickJumping': <FigurePrim>[
    const OvalPrim(Rect.fromLTRB(0.38, 0.08, 0.62, 0.32)),
    const PolyPrim(<Offset>[Offset(0.50, 0.32), Offset(0.50, 0.62)], closed: false),
    const PolyPrim(<Offset>[Offset(0.18, 0.18), Offset(0.50, 0.42), Offset(0.82, 0.18)],
        closed: false),
    const PolyPrim(<Offset>[Offset(0.20, 0.84), Offset(0.50, 0.62), Offset(0.80, 0.84)],
        closed: false),
  ],

  // ---- 鸟类 / Birds ----
  'seagull': <FigurePrim>[
    const PolyPrim(<Offset>[
      Offset(0.04, 0.62), Offset(0.26, 0.30), Offset(0.50, 0.54),
      Offset(0.74, 0.30), Offset(0.96, 0.62),
    ], closed: false),
  ],
  'bird': <FigurePrim>[
    const OvalPrim(Rect.fromLTRB(0.22, 0.34, 0.74, 0.76)),
    const OvalPrim(Rect.fromLTRB(0.60, 0.16, 0.86, 0.44)),
    const PolyPrim(<Offset>[Offset(0.86, 0.26), Offset(0.99, 0.31), Offset(0.86, 0.36)]),
    const PolyPrim(<Offset>[Offset(0.24, 0.48), Offset(0.03, 0.38), Offset(0.06, 0.64)]),
    const PolyPrim(<Offset>[Offset(0.40, 0.76), Offset(0.38, 0.96)], closed: false),
    const PolyPrim(<Offset>[Offset(0.56, 0.76), Offset(0.58, 0.96)], closed: false),
    const OvalPrim(Rect.fromLTRB(0.71, 0.25, 0.77, 0.31)),
  ],
  'owl': <FigurePrim>[
    const OvalPrim(Rect.fromLTRB(0.16, 0.20, 0.84, 0.94)),
    const PolyPrim(<Offset>[Offset(0.24, 0.30), Offset(0.28, 0.05), Offset(0.44, 0.24)]),
    const PolyPrim(<Offset>[Offset(0.76, 0.30), Offset(0.72, 0.05), Offset(0.56, 0.24)]),
    const OvalPrim(Rect.fromLTRB(0.28, 0.32, 0.47, 0.52)),
    const OvalPrim(Rect.fromLTRB(0.53, 0.32, 0.72, 0.52)),
    const OvalPrim(Rect.fromLTRB(0.35, 0.39, 0.40, 0.45)),
    const OvalPrim(Rect.fromLTRB(0.60, 0.39, 0.65, 0.45)),
    const PolyPrim(<Offset>[Offset(0.46, 0.54), Offset(0.54, 0.54), Offset(0.50, 0.64)]),
    const PolyPrim(<Offset>[Offset(0.38, 0.94), Offset(0.34, 1.00)], closed: false),
    const PolyPrim(<Offset>[Offset(0.62, 0.94), Offset(0.66, 1.00)], closed: false),
  ],
  'duck': <FigurePrim>[
    const OvalPrim(Rect.fromLTRB(0.12, 0.44, 0.80, 0.86)),
    const OvalPrim(Rect.fromLTRB(0.58, 0.16, 0.86, 0.48)),
    const PolyPrim(<Offset>[Offset(0.86, 0.28), Offset(1.00, 0.33), Offset(0.86, 0.40)]),
    const PolyPrim(<Offset>[Offset(0.14, 0.54), Offset(0.01, 0.46), Offset(0.05, 0.68)]),
    const OvalPrim(Rect.fromLTRB(0.70, 0.25, 0.76, 0.31)),
  ],

  // ---- 花卉 / Flowers ----
  'tulip': <FigurePrim>[
    const PolyPrim(<Offset>[
      Offset(0.30, 0.30), Offset(0.35, 0.10), Offset(0.43, 0.28), Offset(0.50, 0.08),
      Offset(0.57, 0.28), Offset(0.65, 0.10), Offset(0.70, 0.30), Offset(0.50, 0.46),
    ]),
    const PolyPrim(<Offset>[Offset(0.50, 0.46), Offset(0.50, 0.97)], closed: false),
    const PolyPrim(<Offset>[Offset(0.50, 0.74), Offset(0.26, 0.60), Offset(0.28, 0.80)]),
    const PolyPrim(<Offset>[Offset(0.50, 0.66), Offset(0.74, 0.54), Offset(0.72, 0.72)]),
  ],
  'daisy': <FigurePrim>[
    ..._radialOvals(const Offset(0.50, 0.34), 0.23, 0.11, 8),
    const OvalPrim(Rect.fromLTRB(0.42, 0.26, 0.58, 0.42)),
    const PolyPrim(<Offset>[Offset(0.50, 0.58), Offset(0.50, 0.98)], closed: false),
    const PolyPrim(<Offset>[Offset(0.50, 0.80), Offset(0.28, 0.70), Offset(0.30, 0.88)]),
  ],
  'sunflower': <FigurePrim>[
    ..._radialPetals(const Offset(0.50, 0.34), 0.16, 0.34, 12, 0.16),
    const OvalPrim(Rect.fromLTRB(0.36, 0.20, 0.64, 0.48)),
    const PolyPrim(<Offset>[Offset(0.50, 0.62), Offset(0.50, 0.98)], closed: false),
    const PolyPrim(<Offset>[Offset(0.50, 0.82), Offset(0.72, 0.72), Offset(0.70, 0.90)]),
  ],
  'rose': <FigurePrim>[
    ..._radialOvals(const Offset(0.50, 0.32), 0.20, 0.13, 6),
    _spiral(const Offset(0.50, 0.32), 0.02, 0.16, 2.2, 60),
    const PolyPrim(<Offset>[Offset(0.50, 0.54), Offset(0.50, 0.98)], closed: false),
    const PolyPrim(<Offset>[Offset(0.50, 0.76), Offset(0.26, 0.66), Offset(0.28, 0.84)]),
    const PolyPrim(<Offset>[Offset(0.50, 0.86), Offset(0.74, 0.78), Offset(0.72, 0.94)]),
  ],

  // ---- 自然 / Nature ----
  'tree': <FigurePrim>[
    const OvalPrim(Rect.fromLTRB(0.18, 0.04, 0.82, 0.56)),
    const OvalPrim(Rect.fromLTRB(0.06, 0.24, 0.46, 0.62)),
    const OvalPrim(Rect.fromLTRB(0.54, 0.24, 0.94, 0.62)),
    const PolyPrim(<Offset>[
      Offset(0.44, 0.54), Offset(0.56, 0.54), Offset(0.56, 0.98), Offset(0.44, 0.98),
    ]),
  ],
  'house': <FigurePrim>[
    const PolyPrim(<Offset>[Offset(0.50, 0.04), Offset(0.96, 0.42), Offset(0.04, 0.42)]),
    const PolyPrim(<Offset>[
      Offset(0.12, 0.42), Offset(0.88, 0.42), Offset(0.88, 0.96), Offset(0.12, 0.96),
    ]),
    const PolyPrim(<Offset>[
      Offset(0.42, 0.64), Offset(0.58, 0.64), Offset(0.58, 0.96), Offset(0.42, 0.96),
    ]),
    const PolyPrim(<Offset>[
      Offset(0.20, 0.54), Offset(0.34, 0.54), Offset(0.34, 0.70), Offset(0.20, 0.70),
    ]),
  ],
  'sun': <FigurePrim>[
    const OvalPrim(Rect.fromLTRB(0.28, 0.28, 0.72, 0.72)),
    ..._rays(const Offset(0.50, 0.50), 0.26, 0.46, 12),
  ],
  'mountain': <FigurePrim>[
    const PolyPrim(<Offset>[
      Offset(0.02, 0.92), Offset(0.30, 0.34), Offset(0.45, 0.58),
      Offset(0.62, 0.22), Offset(0.98, 0.92),
    ]),
    const PolyPrim(<Offset>[
      Offset(0.62, 0.22), Offset(0.54, 0.38), Offset(0.62, 0.34), Offset(0.70, 0.40),
    ]),
  ],

  // ---- 动物 / Animals ----
  'cat': <FigurePrim>[
    const OvalPrim(Rect.fromLTRB(0.18, 0.26, 0.82, 0.88)),
    const PolyPrim(<Offset>[Offset(0.24, 0.38), Offset(0.18, 0.06), Offset(0.46, 0.26)]),
    const PolyPrim(<Offset>[Offset(0.76, 0.38), Offset(0.82, 0.06), Offset(0.54, 0.26)]),
    const OvalPrim(Rect.fromLTRB(0.32, 0.46, 0.42, 0.58)),
    const OvalPrim(Rect.fromLTRB(0.58, 0.46, 0.68, 0.58)),
    const PolyPrim(<Offset>[Offset(0.46, 0.62), Offset(0.54, 0.62), Offset(0.50, 0.69)]),
    const PolyPrim(<Offset>[Offset(0.18, 0.62), Offset(0.40, 0.66)], closed: false),
    const PolyPrim(<Offset>[Offset(0.18, 0.72), Offset(0.40, 0.71)], closed: false),
    const PolyPrim(<Offset>[Offset(0.82, 0.62), Offset(0.60, 0.66)], closed: false),
    const PolyPrim(<Offset>[Offset(0.82, 0.72), Offset(0.60, 0.71)], closed: false),
  ],
  'fishFigure': <FigurePrim>[
    const OvalPrim(Rect.fromLTRB(0.08, 0.30, 0.74, 0.78)),
    const PolyPrim(<Offset>[Offset(0.70, 0.54), Offset(0.98, 0.28), Offset(0.98, 0.80)]),
    const PolyPrim(<Offset>[Offset(0.34, 0.32), Offset(0.46, 0.12), Offset(0.54, 0.34)]),
    const OvalPrim(Rect.fromLTRB(0.18, 0.44, 0.26, 0.52)),
  ],
};

/// 组合图形（交通工具、火柴人、花卉、鸟类等）
///
/// 由一组比例坐标的元件组成，随拖拽矩形整体缩放。所有图形共用本类，
/// 通过 [figureId] 区分，因此新增图形只需在 [kFigures] 中添加数据。
///
/// Composite figure (vehicles, stickmen, flowers, birds, ...).
///
/// Built from primitives in fractional coordinates that scale with the drag
/// rectangle. Every figure shares this one class and is identified by
/// [figureId], so adding a new figure is just data in [kFigures].
class FigureShape extends DragShape {
  FigureShape(this.figureId);

  FigureShape.data({
    required this.figureId,
    required super.startPoint,
    required super.endPoint,
    required super.paint,
  }) : super.data();

  factory FigureShape.fromJson(Map<String, dynamic> d) => FigureShape.data(
        figureId: (d['figureId'] ?? '') as String,
        startPoint: jsonToOffset(d['startPoint'] as Map<String, dynamic>),
        endPoint: jsonToOffset(d['endPoint'] as Map<String, dynamic>),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  /// 图形标识（对应 [kFigures] 的键）/ Figure key into [kFigures]
  final String figureId;

  @override
  String get contentType => 'FigureShape';

  Offset _map(Rect r, Offset f) => Offset(r.left + f.dx * r.width, r.top + f.dy * r.height);

  Rect _mapRect(Rect r, Rect f) => Rect.fromLTRB(
        r.left + f.left * r.width,
        r.top + f.top * r.height,
        r.left + f.right * r.width,
        r.top + f.bottom * r.height,
      );

  @override
  void drawShape(Canvas canvas, Rect r, Offset s, Offset e, Paint paint) {
    final List<FigurePrim>? prims = kFigures[figureId];
    if (prims == null || r.isEmpty) {
      return;
    }

    // 开放折线在填充模式下改用描边，避免被错误地填成色块
    // Open polylines fall back to stroke in fill mode so they don't blob
    final Paint linePaint = paint.style == PaintingStyle.fill
        ? paint.copyWith(style: PaintingStyle.stroke, strokeWidth: max(1.0, paint.strokeWidth))
        : paint;

    for (final FigurePrim prim in prims) {
      switch (prim) {
        case OvalPrim(:final Rect rect):
          canvas.drawOval(_mapRect(r, rect), paint);
        case PolyPrim(:final List<Offset> points, :final bool closed):
          if (points.isEmpty) {
            continue;
          }
          final Path path = Path();
          for (int i = 0; i < points.length; i++) {
            final Offset pt = _map(r, points[i]);
            i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
          }
          if (closed) {
            path.close();
          }
          canvas.drawPath(path, closed ? paint : linePaint);
      }
    }
  }

  @override
  FigureShape copy() => FigureShape(figureId);

  @override
  Map<String, dynamic> toContentJson() =>
      <String, dynamic>{...super.toContentJson(), 'figureId': figureId};
}
