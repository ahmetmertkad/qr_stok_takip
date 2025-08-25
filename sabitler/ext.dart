import 'package:flutter/material.dart';

const String arka_renk = "#5E80A9";

class renk extends Color {
  static int _donustur(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  renk(final String renk_kodu) : super(_donustur(renk_kodu));
}
