import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/logs_notifier.dart';

class DescribeFoodWidget extends ConsumerStatefulWidget {
  const DescribeFoodWidget({Key? key}) : super(key: key);

  @override
  _DescribeFoodWidgetState createState() => _DescribeFoodWidgetState();
}

class _DescribeFoodWidgetState extends ConsumerState<DescribeFoodWidget> {
  final TextEditingController _foodController = TextEditingController();
  final FocusNode _foodFocusNode = FocusNode();

  void _addFoodLog() {
    final description = _foodController.text.trim();
    if (description.isNotEmpty) {
      ref.read(logsProvider.notifier).addLogItemByDescription(
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
      FocusScope.of(context).requestFocus(_foodFocusNode);
    });
  }

  @override
  void dispose() {
    _foodController.dispose();
    _foodFocusNode.dispose();
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
                'Describe Food',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            // Food Description Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: TextField(
                controller: _foodController,
                focusNode: _foodFocusNode,
                decoration: InputDecoration(
                  hintText: 'Enter food description',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addFoodLog(),
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}