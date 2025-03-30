import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';

class CaloriesCard extends StatelessWidget {
  final double caloriesLeft;
  final double caloriesTotal;

  const CaloriesCard({
    super.key,
    required this.caloriesLeft,
    required this.caloriesTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caloriesLeft.toInt().toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Calories left',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            CircularPercentIndicator(
              radius: 50,
              lineWidth: 10,
              percent: max(0,min(1, (caloriesTotal - caloriesLeft) / caloriesTotal)),
              center: Icon(Icons.local_fire_department, color: Colors.orange),
              progressColor: Colors.green,
              backgroundColor: Colors.green.shade100,
            ),
          ],
        ),
      ),
    );
  }
}