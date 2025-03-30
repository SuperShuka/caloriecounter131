class NutritionService {
  // Calculate Basal Metabolic Rate (BMR) using Mifflin-St Jeor Equation
  double calculateBMR(String gender, int age, double height, double weight) {
    if (gender.toLowerCase() == 'male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  // Calculate Total Daily Energy Expenditure (TDEE)
  double calculateTDEE(double bmr, String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'beginner':
        return bmr * 1.2; // Sedentary (little or no exercise)
      case 'intermediate':
        return bmr * 1.55; // Moderate exercise (3-5 days per week)
      case 'advanced':
        return bmr * 1.725; // Heavy exercise (6-7 days per week)
      default:
        return bmr * 1.375; // Default to light exercise
    }
  }

  // Calculate daily calorie needs based on user's information and goals
  int calculateDailyCalories(
      {required String gender,
        required int age,
        required double height,
        required double weight,
        required String activityLevel,}) {

    // Calculate BMR and TDEE
    double bmr = calculateBMR(gender, age, height, weight);
    double tdee = calculateTDEE(bmr, activityLevel);

    String goal = "lose_weight";
    // Adjust calories based on goal
    switch (goal.toLowerCase()) {
      case 'lose_weight':
        return (tdee - 500).round(); // Create a 500 calorie deficit
      case 'gain_weight':
        return (tdee + 500).round(); // Create a 500 calorie surplus
      case 'maintain_weight':
      default:
        return tdee.round(); // Maintain weight
    }
  }

  // Calculate macro distribution based on calorie needs and goal
  Map<String, int> calculateMacroDistribution({
    required int calories,
  }) {
    // Default protein requirement: 1.8g per kg of body weight
    double proteinPercentage;
    double fatPercentage;
    double carbsPercentage;
    String goal = "lose_weight";

    switch (goal.toLowerCase()) {
      case 'lose_weight':
      // Higher protein for muscle preservation during weight loss
        proteinPercentage = 0.25; // 30%
        fatPercentage = 0.30; // 30%
        carbsPercentage = 0.45; // 40%
        break;
      case 'gain_weight':
      // Higher carbs for energy to build muscle
        proteinPercentage = 0.25; // 25%
        fatPercentage = 0.30; // 25%
        carbsPercentage = 0.45; // 50%
        break;
      case 'maintain_weight':
      default:
      // Balanced diet for maintenance
        proteinPercentage = 0.25; // 25%
        fatPercentage = 0.30; // 30%
        carbsPercentage = 0.45; // 45%
        break;
    }

    // Calculate grams of each macro
    // Protein and carbs are 4 calories per gram, fat is 9 calories per gram
    int proteinCalories = (calories * proteinPercentage).round();
    int fatCalories = (calories * fatPercentage).round();
    int carbsCalories = (calories * carbsPercentage).round();

    int proteinGrams = (proteinCalories / 4).round();
    int fatGrams = (fatCalories / 9).round();
    int carbsGrams = (carbsCalories / 4).round();

    return {
      'protein': proteinGrams,
      'fat': fatGrams,
      'carbs': carbsGrams,
    };
  }

  // Calculate recommended water intake (in ml)
  int calculateWaterIntake(double weight, String activityLevel) {
    // Base recommendation: 30ml per kg of body weight
    double baseWater = weight * 30;

    // Adjust for activity level
    switch (activityLevel.toLowerCase()) {
      case 'beginner':
        return baseWater.round();
      case 'intermediate':
        return (baseWater * 1.2).round();
      case 'advanced':
        return (baseWater * 1.4).round();
      default:
        return baseWater.round();
    }
  }
}