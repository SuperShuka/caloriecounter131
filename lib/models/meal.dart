import 'package:cloud_firestore/cloud_firestore.dart';

class Meal {
  final String id;
  final String userId;
  final String name;
  final String? imageUrl;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String date;
  final Timestamp timestamp;

  Meal({
    required this.id,
    required this.userId,
    required this.name,
    this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.date,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'imageUrl': imageUrl,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'date': date,
      'timestamp': timestamp,
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map, String documentId) {
    return Meal(
      id: documentId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'],
      calories: map['calories'] ?? 0,
      protein: map['protein'] ?? 0,
      carbs: map['carbs'] ?? 0,
      fat: map['fat'] ?? 0,
      date: map['date'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }

  factory Meal.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Meal.fromMap(data, doc.id);
  }
}