import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner_plus/flutter_barcode_scanner_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:openfoodfacts/openfoodfacts.dart';

import '../models/log_item.dart';
import 'firestore_logs_service.dart';
import 'nutrition_api_service.dart';

final nutritionApiServiceProvider = Provider((ref) => NutritionApiService());
final firebaseLogsServiceProvider = Provider((ref) => FirebaseLogsService());

class LogsNotifier extends StateNotifier<List<LogItem>> {
  final NutritionApiService _nutritionService;
  final FirebaseLogsService _firebaseLogsService;

  LogsNotifier(this._nutritionService, this._firebaseLogsService) : super([]);

  Future<void> addLogItemByDescription(
      BuildContext context,
      String foodDescription,
      ) async {
    try {
      final logItems = await _nutritionService.getNutritionByDescription(foodDescription);

      if (logItems != []) {
        for (var logItem in logItems) {
          await _firebaseLogsService.addLogItem(logItem);
        }
      } else {
        _showErrorDialog(context, 'Could not find nutrition information', 'Could not find nutrition information for "$foodDescription". Please try a more specific description like "chicken breast".');
      }
    } catch (e) {
      print("Error adding log item by description: $e");
    }
  }

  Future<void> addLogItemByBarcode() async {
    try {
      OpenFoodAPIConfiguration.userAgent = UserAgent(name: 'fitness_app');

      OpenFoodAPIConfiguration.globalLanguages = <OpenFoodFactsLanguage>[OpenFoodFactsLanguage.RUSSIAN, OpenFoodFactsLanguage.ENGLISH];

      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", // Color of the scan screen
          "Cancel",  // Cancel button text
          true,      // Show flash icon
          ScanMode.BARCODE // Scan mode
      );

      if (barcodeScanRes != '-1') {
        final logItem = await _nutritionService.getNutritionByBarcode(barcodeScanRes);

        if (logItem != null) {
          await _firebaseLogsService.addLogItem(logItem);
        } else {
          print('Could not find nutrition for this barcode');
        }
      }
    } catch (e) {
      print('Barcode scanning error: $e');
    }
  }

  Future<void> addWorkoutByDescription(
      BuildContext context,
      String workoutDescription,
      ) async {
    try {
      final logItems = await _nutritionService.getWorkoutByDescription(workoutDescription);

      if (logItems.isNotEmpty) {
        for (var logItem in logItems) {
          await _firebaseLogsService.addLogItem(logItem);
        }
      } else {
        _showErrorDialog(
            context,
            'Workout Not Found',
            'Could not find workout information for "$workoutDescription". Please try a more specific description like "running 30 minutes" or "biking 5 miles".'
        );
      }
    } catch (e) {
      print("Error adding workout by description: $e");
      _showErrorDialog(
          context,
          'Error',
          'An unexpected error occurred while fetching workout data. Please try again later.'
      );
    }
  }

  Future<void> addLogItemByAiScan(BuildContext context) async {
    final apiiKey = '62919a9541524dc2ac390cc43eb39deb';
    final baseUrl = 'https://api.clarifai.com/v2/models/food-item-recognition/outputs';
    final userId = '6vd8ir7ptuwd';
    final appId = 'food-recognition';
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 90);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        final response = await http.post(
          Uri.parse(baseUrl),
          headers: {
            'Authorization': 'Key $apiiKey',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'inputs': [
              {
                'data': {
                  'image': {
                    'base64': base64Image,
                  },
                },
              },
            ],
          }),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          addLogItemByDescription(context, data['outputs'][0]['data']['concepts'][0]['name']);
          // for (var concept in data['outputs'][0]['data']['concepts']) {
          //   if (concept['value'] > 0.80) {
          //     addLogItemByDescription(context, concept['name']);
          //   }
          // }
        }
        else{
          print(response.body);
        }
      }
    } catch (e) {
      print("AI scan error: $e");
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    "Tip: Try to be more specific with your description.",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 10,
      ),
    );
  }

  Future<void> syncLogsToFirebase() async {
    try {
      await _firebaseLogsService.syncLogsToFirebase(state);
    } catch (e) {
      print('Error syncing logs to Firebase: $e');
    }
  }

  Future<void> loadLogsFromFirebase(DateTime date) async {
    try {
      final logsStream = _firebaseLogsService.getLogs(date);
      logsStream.listen((logs) {
        state = logs;
      });
    } catch (e) {
      print('Error loading logs from Firebase: $e');
    }
  }

  void addLogItem(LogItem logItem) {
    state = [...state, logItem];
    syncLogsToFirebase();
  }
}

// Provider for logs state
final logsProvider = StateNotifierProvider<LogsNotifier, List<LogItem>>((ref) {
  return LogsNotifier(
      ref.read(nutritionApiServiceProvider),
      ref.read(firebaseLogsServiceProvider)
  );
});