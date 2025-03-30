import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../models/macro_item.dart';

class MacroBreakdown extends StatelessWidget {
  final List<MacroItem> macros;

  const MacroBreakdown({
    super.key,
    required this.macros,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: macros.map((macro) =>
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    CircularPercentIndicator(
                      radius: 35,
                      lineWidth: 8,
                      percent: min(1 - (macro.left / macro.total), 1),
                      center: Icon(macro.icon, color: macro.color, size: 20),
                      progressColor: macro.color,
                      backgroundColor: macro.color.withOpacity(0.2),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${macro.left}g',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${macro.name} left',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
        ).toList(),
      ),
    );
  }
}