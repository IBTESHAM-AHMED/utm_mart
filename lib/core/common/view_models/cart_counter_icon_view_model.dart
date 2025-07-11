import 'package:flutter/material.dart';
import 'package:utmmart/core/utils/constants/colors.dart';

class CartCounterIconModel {
  final VoidCallback? onPressed;
  final Color? color;
  final int? count;
  CartCounterIconModel({
    this.count = 0,
    this.onPressed,
    this.color=TColors.white,
  });
}
