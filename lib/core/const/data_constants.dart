class DataConstants {
  // Default nutrition goals
  static const int defaultCalorieGoal = 2000;
  static const int defaultProteinGoal = 150; // in grams
  static const int defaultCarbsGoal = 225; // in grams
  static const int defaultFatGoal = 67; // in grams
  static const int defaultWaterGoal = 2000; // in ml

  // Activity levels with multipliers
  static const double sedentaryMultiplier = 1.2;
  static const double lightlyActiveMultiplier = 1.375;
  static const double moderatelyActiveMultiplier = 1.55;
  static const double veryActiveMultiplier = 1.725;
  static const double extraActiveMultiplier = 1.9;

  // Food serving sizes
  static const Map<String, double> servingSizes = {
    'cup': 240.0,
    'tablespoon': 15.0,
    'teaspoon': 5.0,
    'ounce': 28.35,
    'gram': 1.0,
    'pound': 453.6,
  };

  // Weight tracking defaults
  static const double minWeight = 30.0; // kg
  static const double maxWeight = 300.0; // kg

  // User preferences keys
  static const String themePreferenceKey = 'app_theme';
  static const String unitSystemKey = 'unit_system';
  static const String notificationsEnabledKey = 'notifications_enabled';
}