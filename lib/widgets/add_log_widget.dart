import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner_plus/flutter_barcode_scanner_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firestore_logs_service.dart';
import '../services/nutrition_api_service.dart';
import '../utils/debug_print.dart';
import '../services/logs_notifier.dart';
import 'describe_food_widget.dart';
import 'describe_workout_widget.dart';

class AddLogWidget extends ConsumerWidget {
  const AddLogWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F5DC), Color(0xFFE5E5DB)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Add Log',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                LogActionButton(
                  icon: Icons.fitness_center, // Changed icon to fitness
                  label: 'Workout', // Changed label from 'Saved' to 'Workout'
                  onTap: () {
                    Navigator.pop(context);
                    // Open workout description widget
                    showModalBottomSheet(
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      isScrollControlled: true,
                      builder: (context) => Padding(
                        padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom
                        ),
                        child: DescribeWorkoutWidget(),
                      ),
                    );
                  },
                ),
                LogActionButton(
                  icon: Icons.qr_code,
                  label: 'Barcode',
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(logsProvider.notifier).addLogItemByBarcode();
                  },
                ),
                LogActionButton(
                  icon: Icons.document_scanner,
                  label: 'AI Scan',
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(logsProvider.notifier).addLogItemByAiScan(context);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  isScrollControlled: true,  // This allows the sheet to move up with the keyboard
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom
                    ),
                    child: DescribeFoodWidget(),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[600]),
                    SizedBox(width: 10),
                    Text(
                      'Describe food',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

class LogActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const LogActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 90,  // Wider button
            height: 90,  // Added height
            decoration: BoxDecoration(
              color: Colors.grey[100],  // Light grey background
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 40,  // Larger icon
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,  // Slightly larger text
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}