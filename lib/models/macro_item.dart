import 'package:flutter/material.dart';

class MacroItem {
  final String name;
  final int left;
  final int total;
  final IconData icon;
  final Color color;

  MacroItem({
    required this.name,
    required this.left,
    required this.total,
    required this.icon,
    required this.color,
  });
}