import 'dart:ui';

import 'package:fluttertoast/fluttertoast.dart';

void showToast({required String message}) {
  Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: const Color(0xFF283039),
      // backgroundColor: Colors.red,
      // textColor: Colors.white,
      fontSize: 16.0);
}