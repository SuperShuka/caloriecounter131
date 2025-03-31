import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:openfoodfacts/openfoodfacts.dart';
import 'dart:convert';
import '../models/log_item.dart';
import '../utils/debug_print.dart';
import 'package:translator/translator.dart';

class NutritionApiService {
  static const String appId = 'abf1ae27';
  static const String apiKey = '2c8f12ecd62f5367303ecccd3df5e55f';
  static const String baseUrl = 'https://trackapi.nutritionix.com/v2/natural/nutrients';
  static const String workoutBaseUrl = 'https://trackapi.nutritionix.com/v2/natural/exercise';
  final translator = GoogleTranslator();


  Future<String> translateru(String input) async {
    final result = await translator.translate(input, from: 'ru', to: 'en');
    return result.text;
  }

  Future<String> translateen(String input) async {
    final result = await translator.translate(input, from: 'en', to: 'ru');
    return result.text;
  }

  Future<List<LogItem>> getNutritionByDescription(String foodDescription) async {
    try {
      final desc = await translateru(foodDescription);
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'x-app-id': appId,
          'x-app-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'query': desc,
        }),
      );

      dPrint(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<LogItem> logItems = [];
        int duration_add = 0;

        for (var food in data['foods']) {
          final nm = await translateen(food['food_name']);
          logItems.add(LogItem(
            name: nm ?? foodDescription,
            calories: food['nf_calories']?.toDouble() ?? 0.0,
            timestamp: DateTime.now().add(Duration(seconds: duration_add++)),
            type: LogItemType.meal,
            macros: [
              MacroDetail(
                  icon: '🍗',
                  value: food['nf_protein']?.toDouble() ?? 0.0
              ),
              MacroDetail(
                  icon: '🍞',
                  value: food['nf_total_carbohydrate']?.toDouble() ?? 0.0
              ),
              MacroDetail(
                  icon: '🧀',
                  value: food['nf_total_fat']?.toDouble() ?? 0.0
              ),
            ],
            weight: food['serving_weight_grams']?.toInt() ?? 0,
          ));
        }

        return logItems;
      }
    } catch (e) {
      dPrint('Nutrition API Error: $e');
    }
    return [];
  }

  Future<List<LogItem>> getWorkoutByDescription(String workoutDescription) async {
    try {
      final desc = await translateru(workoutDescription);
      final response = await http.post(
        Uri.parse(workoutBaseUrl),
        headers: {
          'x-app-id': appId,
          'x-app-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'query': desc,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['exercises'] == null || data['exercises'].isEmpty) {
          // Return empty list to trigger error handling
          return [];
        }

        List<LogItem> logItems = [];
        int duration_add = 0;

        for (var exercise in data['exercises']) {
          final nm = await translateen(exercise['name']);
          logItems.add(LogItem(
            name: nm ?? workoutDescription,
            calories: -exercise['nf_calories']?.toDouble() ?? 0.0,
            timestamp: DateTime.now().add(Duration(seconds: duration_add++)),
            type: LogItemType.training,
          ));
        }
        return logItems;
      } else {
        print('Workout API returned status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Workout API Error: $e');
      return [];
    }
  }

  Future<LogItem?> getNutritionByBarcode(String barcode) async {
    try {

      OpenFoodAPIConfiguration.userAgent = UserAgent(name: 'fitness_app');

      OpenFoodAPIConfiguration.globalLanguages = <OpenFoodFactsLanguage>[OpenFoodFactsLanguage.RUSSIAN, OpenFoodFactsLanguage.ENGLISH];
      ProductResultV3 result = await OpenFoodAPIClient.getProductV3(ProductQueryConfiguration(
        barcode,
        language: OpenFoodFactsLanguage.RUSSIAN, version: ProductQueryVersion.v3,
      ));

      if (result.product != null) {
        final product = result.product!;

        return LogItem(
          name: product.productName ?? 'Scanned Item',
          calories: product.nutriments?.getValue(Nutrient.energyKCal, PerSize.oneHundredGrams)?.toDouble() ?? 0.0,
          timestamp: DateTime.now(),
          type: LogItemType.meal,
          macros: [
            MacroDetail(
              icon: '🍗',
              value: product.nutriments?.getValue(Nutrient.proteins, PerSize.oneHundredGrams)?.toDouble() ?? 0.0,
            ),
            MacroDetail(
              icon: '🍞',
              value: product.nutriments?.getValue(Nutrient.carbohydrates, PerSize.oneHundredGrams)?.toDouble() ?? 0.0,
            ),
            MacroDetail(
              icon: '🧀',
              value: product.nutriments?.getValue(Nutrient.fat, PerSize.oneHundredGrams)?.toDouble() ?? 0.0,
            ),
          ],
          weight: 100,
        );
      }
    } catch (e) {
      print('OpenFoodFacts Barcode Lookup Error: $e');
    }
    return null;
  }
}