import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meal.dart';

class MealService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user's meals for a specific date
  Stream<List<Meal>> getMealsForDate(String date) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('meals')
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: date)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Meal.fromDocument(doc)).toList();
    });
  }

  // Add a new meal
  Future<void> addMeal(Meal meal) async {
    await _firestore.collection('meals').add(meal.toMap());
  }

  // Update an existing meal
  Future<void> updateMeal(Meal meal) async {
    await _firestore.collection('meals').doc(meal.id).update(meal.toMap());
  }

  // Delete a meal
  Future<void> deleteMeal(String mealId) async {
    await _firestore.collection('meals').doc(mealId).delete();
  }

  // Get user's nutrition summary for a specific date
  Future<Map<String, dynamic>> getNutritionSummary(String date) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return {
        'totalCalories': 0,
        'totalProtein': 0,
        'totalCarbs': 0,
        'totalFat': 0,
      };
    }

    final snapshot = await _firestore
        .collection('meals')
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: date)
        .get();

    int totalCalories = 0;
    int totalProtein = 0;
    int totalCarbs = 0;
    int totalFat = 0;

    for (var doc in snapshot.docs) {
      final meal = Meal.fromDocument(doc);
      totalCalories += meal.calories;
      totalProtein += meal.protein;
      totalCarbs += meal.carbs;
      totalFat += meal.fat;
    }

    return {
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
    };
  }
}