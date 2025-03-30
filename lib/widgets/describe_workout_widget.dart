import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/logs_notifier.dart';

class DescribeWorkoutWidget extends ConsumerStatefulWidget {
  const DescribeWorkoutWidget({Key? key}) : super(key: key);

  @override
  _DescribeWorkoutWidgetState createState() => _DescribeWorkoutWidgetState();
}

class _DescribeWorkoutWidgetState extends ConsumerState<DescribeWorkoutWidget> {
  final TextEditingController _workoutController = TextEditingController();
  final FocusNode _workoutFocusNode = FocusNode();

  void _addWorkoutLog() {
    final description = _workoutController.text.trim();
    if (description.isNotEmpty) {
      ref.read(logsProvider.notifier).addWorkoutByDescription(
          context,
          description
      );
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    // Automatically focus the text field when the widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_workoutFocusNode);
    });
  }

  @override
  void dispose() {
    _workoutController.dispose();
    _workoutFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F5DC), Color(0xFFE5E5DB)], // Beige gradient
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
                'Describe Workout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            // Workout Description Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: TextField(
                controller: _workoutController,
                focusNode: _workoutFocusNode,
                decoration: InputDecoration(
                  hintText: 'Enter workout description (e.g. running 30 min)',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addWorkoutLog(),
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}