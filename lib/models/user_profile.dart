class UserProfile {
  final String userId;
  final String email;
  final String displayName;
  final String gender;
  final int age;
  final double height;
  final double weight;
  final double targetWeight;
  final String primaryGoal;
  final String workoutFrequency;
  final double weeklyGoal;
  final int dailyCalories;
  final int proteinGoal;
  final int carbsGoal;
  final int fatGoal;
  final int waterGoal;
  final DateTime createdAt;
  final DateTime lastUpdated;

  UserProfile({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    required this.targetWeight,
    required this.primaryGoal,
    required this.workoutFrequency,
    required this.weeklyGoal,
    required this.dailyCalories,
    required this.proteinGoal,
    required this.carbsGoal,
    required this.fatGoal,
    required this.waterGoal,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      userId: data['userId'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      gender: data['gender'] ?? '',
      age: data['age'] ?? '',
      height: (data['height'] ?? 0).toDouble(),
      weight: (data['weight'] ?? 0).toDouble(),
      targetWeight: (data['targetWeight'] ?? 0).toDouble(),
      primaryGoal: data['primaryGoal'] ?? '',
      workoutFrequency: data['workoutFrequency'] ?? '',
      weeklyGoal: (data['weeklyGoal'] ?? 0).toDouble(),
      dailyCalories: data['dailyCalories'] ?? 0,
      proteinGoal: data['proteinGoal'] ?? 0,
      carbsGoal: data['carbsGoal'] ?? 0,
      fatGoal: data['fatGoal'] ?? 0,
      waterGoal: data['waterGoal'] ?? 0,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      lastUpdated: data['lastUpdated']?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'gender': gender,
      'age': age,
      'height': height,
      'weight': weight,
      'targetWeight': targetWeight,
      'primaryGoal': primaryGoal,
      'workoutFrequency': workoutFrequency,
      'weeklyGoal': weeklyGoal,
      'dailyCalories': dailyCalories,
      'proteinGoal': proteinGoal,
      'carbsGoal': carbsGoal,
      'fatGoal': fatGoal,
      'waterGoal': waterGoal,
      'createdAt': createdAt,
      'lastUpdated': lastUpdated,
    };
  }

  // Create a copy with updated values
  UserProfile copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? gender,
    int? age,
    double? height,
    double? weight,
    double? targetWeight,
    String? primaryGoal,
    String? workoutFrequency,
    double? weeklyGoal,
    int? dailyCalories,
    int? proteinGoal,
    int? carbsGoal,
    int? fatGoal,
    int? waterGoal,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      targetWeight: targetWeight ?? this.targetWeight,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      workoutFrequency: workoutFrequency ?? this.workoutFrequency,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      carbsGoal: carbsGoal ?? this.carbsGoal,
      fatGoal: fatGoal ?? this.fatGoal,
      waterGoal: waterGoal ?? this.waterGoal,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

extension UserProfileCalculations on UserProfile {
  double calculateBMR() {
    if (gender.toLowerCase() == 'male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else if (gender.toLowerCase() == 'female') {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
    return (10 * weight) + (6.25 * height) - (5 * age);
  }

  double _getActivityMultiplier() {
    switch (workoutFrequency.toLowerCase()) {
      case 'sedentary':
        return 1.2;
      case 'light':
        return 1.375;
      case 'moderate':
        return 1.55;
      case 'very active':
        return 1.725;
      case 'extra active':
        return 1.9;
      default:
        return 1.375; // Default to light activity if unrecognized.
    }
  }

  // Calculate Total Daily Energy Expenditure (TDEE)
  double calculateTDEE() {
    return calculateBMR() * _getActivityMultiplier();
  }

  // Calculate calorie adjustment based on weekly weight goal
  int calculateDailyCalories() {
    double tdee = calculateTDEE();
    // If a weekly goal is provided (non-zero), use that for more precise adjustment.
    // The weeklyGoal is assumed to be in kg/week. Approximately 7700 calories correspond to 1kg.
    if (primaryGoal.toLowerCase().contains('lose')) {
      if (weeklyGoal < 0) {
        double calorieDeficit = (-weeklyGoal * 7700) / 7;
        return (tdee - calorieDeficit).round();
      }
      return (tdee - 500).round();
    } else if (primaryGoal.toLowerCase().contains('gain')) {
      if (weeklyGoal > 0) {
        double calorieSurplus = (weeklyGoal * 7700) / 7;
        return (tdee + calorieSurplus).round();
      }
      return (tdee + 500).round();
    } else {
      return tdee.round();
    }
  }

  // Macronutrient Recommendations
  Map<String, int> calculateMacronutrients() {
    int calories = calculateDailyCalories();
    double proteinRatio;
    double fatRatio;
    double carbRatio;

    // Set macro ratios based on the primary goal.
    if (primaryGoal.toLowerCase().contains('lose')) {
      // Higher protein to preserve muscle and a moderate carb intake.
      proteinRatio = 0.20;
      fatRatio = 0.30;
      carbRatio = 0.50;
    } else if (primaryGoal.toLowerCase().contains('gain')) {
      // Slightly lower protein with higher carbs for energy.
      proteinRatio = 0.20;
      fatRatio = 0.35;
      carbRatio = 0.45;
    } else {
      // Balanced distribution for weight maintenance.
      proteinRatio = 0.20;
      fatRatio = 0.35;
      carbRatio = 0.45;
    }

    // Calculate calories for each macronutrient.
    int proteinCalories = (calories * proteinRatio).round();
    int fatCalories = (calories * fatRatio).round();
    // Assign remaining calories to carbs.
    int carbCalories = calories - (proteinCalories + fatCalories);

    // Convert calories to grams: Protein & Carbs (4 cal/g), Fat (9 cal/g).
    int proteinGrams = (proteinCalories / 4).round();
    int fatGrams = (fatCalories / 9).round();
    int carbGrams = (carbCalories / 4).round();

    return {
      'protein': proteinGrams,
      'fat': fatGrams,
      'carbs': carbGrams,
    };
  }

  int calculateWaterGoal() {
    // Base water recommendation: 35 ml per kg of body weight.
    double baseWater = weight * 35;

    // Increase water needs based on activity level.
    if (workoutFrequency.toLowerCase() == 'very active') {
      return (baseWater * 1.2).round();
    } else if (workoutFrequency.toLowerCase() == 'extra active') {
      return (baseWater * 1.5).round();
    }
    return baseWater.round();
  }

  // Method to update profile with calculated goals
  UserProfile updateNutritionGoals() {
    int dailyCals = calculateDailyCalories();
    Map<String, int> macros = calculateMacronutrients();
    int water = calculateWaterGoal();
    return copyWith(
      dailyCalories: dailyCals,
      proteinGoal: macros['protein']!,
      carbsGoal: macros['carbs']!,
      fatGoal: macros['fat']!,
      waterGoal: water,
      lastUpdated: DateTime.now(),
    );
  }
}
