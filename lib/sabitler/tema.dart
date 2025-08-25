import 'package:flutter/material.dart';

class Tema {
  InputDecoration inputDec() {
    return InputDecoration(
      hintText: "E-mail adresinizi giriniz",
      hintStyle: TextStyle(),
      border: InputBorder.none,
      prefixIcon: Padding(
        padding: EdgeInsets.only(right: 8), // Sağdan boşluk
        child: Icon(Icons.people_alt_outlined),
      ),
    );
  }
}
