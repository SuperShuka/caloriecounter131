import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner_plus/flutter_barcode_scanner_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:openfoodfacts/openfoodfacts.dart';

import '../models/log_item.dart';
import 'ErrorHandler.dart';
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
      final logItems = await _nutritionService.getNutritionByDescription(context, foodDescription);

      if (logItems != []) {
        for (var logItem in logItems) {
          await _firebaseLogsService.addLogItem(logItem);
        }
      } else {
        ErrorHandler.showWarning(context, "Не удалось найти информацию о продукте.");
      }
    } catch (e) {
      ErrorHandler.showError(context, "Ошибка: $e");
    }
  }

  Future<void> addLogItemByBarcode(BuildContext context) async {
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
        final logItem = await _nutritionService.getNutritionByBarcode(context, barcodeScanRes);

        if (logItem != null) {
          await _firebaseLogsService.addLogItem(logItem);
        } else {
          ErrorHandler.showWarning(context, "Не удалось найти информацию о продукте.");
        }
      }
    } catch (e) {
      ErrorHandler.showError(context, "Ошибка: $e");
    }
  }

  Future<void> addWorkoutByDescription(
      BuildContext context,
      String workoutDescription,
      ) async {
    try {
      final logItems = await _nutritionService.getWorkoutByDescription(context, workoutDescription);

      if (logItems.isNotEmpty) {
        for (var logItem in logItems) {
          await _firebaseLogsService.addLogItem(logItem);
        }
      } else {
        ErrorHandler.showWarning(context, "Не удалось найти информацию о тренировке.");
      }
    } catch (e) {
      ErrorHandler.showError(context, "Ошибка: $e");
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
          // addLogItemByDescription(context, data['outputs'][0]['data']['concepts'][0]['name']);
          for (var concept in data['outputs'][0]['data']['concepts']) {
            if (concept['value'] > 0.90) {
              addLogItemByDescription(context, concept['name']);
            }
          }
        }
        else{
          ErrorHandler.showError(context, "Не удалось найти информацию о продукте.");
        }
      }
    } catch (e) {
      ErrorHandler.showError(context, "Ошибка: $e");
    }
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
    state = [logItem, ...state];
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