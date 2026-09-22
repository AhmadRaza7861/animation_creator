import 'package:flutter/material.dart';

extension ExOffset on Offset {
  Map<String, dynamic> toJson() {
    return <String, dynamic>{'dx': dx, 'dy': dy};
  }
}

Offset jsonToOffset(Map<String, dynamic>? data) {
  if (data == null) return Offset.zero;
  return Offset(
    (data['dx'] as num?)?.toDouble() ?? 0.0,
    (data['dy'] as num?)?.toDouble() ?? 0.0,
  );
}
