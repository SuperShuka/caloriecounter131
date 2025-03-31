import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../services/nutrition_service.dart';
import 'auth_wrapper.dart';

class UserProfileSetup extends StatefulWidget {
  const UserProfileSetup({Key? key}) : super(key: key);

  @override
  _UserProfileSetupState createState() => _UserProfileSetupState();
}

class _UserProfileSetupState extends State<UserProfileSetup>
    with SingleTickerProviderStateMixin {
  // Controllers
  final PageController _pageController = PageController();
  late AnimationController _animationController;

  // State variables
  bool _isLoading = false;
  int _currentStep = 0;
  final int _totalSteps = 5;

  // User profile data
  String? _gender;
  int? _age;
  double _height = 170;
  double _weight = 70;
  double _targetWeight = 70;
  String? _primaryGoal;
  String? _workoutFrequency;
  double _weeklyGoal = 0.5;

  // Lists for dropdown options
  final List<String> _genderOptions = ['Male', 'Female'];
  final List<String> _goalOptions = [
    'Lose Weight',
    'Maintain Weight',
    'Gain Weight',
    'Build Muscle',
  ];
  final List<String> _workoutOptions = [
    'Sedentary',
    'Light Exercise',
    'Moderate Exercise',
    'Active',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  bool applyFix() {
    if (_currentStep == 2 || _currentStep == 3) {
      return true;
    }
    if (_targetWeight == _weight){
      _primaryGoal = "Maintain Weight";
    }
    else if (_targetWeight > _weight){
      _primaryGoal = "Gain Weight";
    }
    else if (_targetWeight < _weight){
      _primaryGoal = "Lose Weight";
    }
    return true;
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveUserDataAndNavigate() async {
    setState(() {
      _isLoading = true;
      _pageController.animateToPage(
        _totalSteps,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception("No authenticated user found");
      }
      final age = _age;

      if (_targetWeight < _weight){
        _weeklyGoal = -_weeklyGoal;
      }

      final nutritionService = NutritionService();
      final dailyCalories = nutritionService.calculateDailyCalories(
        gender: _gender!,
        age: age!,
        height: _height,
        weight: _weight,
        activityLevel: _workoutFrequency!,
        goal: _primaryGoal!,
      );

      final macros = nutritionService.calculateMacroDistribution(
        calories: dailyCalories,
      );


      UserProfile userProfile = UserProfile(
        userId: currentUser.uid,
        email: currentUser.email ?? '',
        displayName: currentUser.displayName ?? '',
        gender: _gender!,
        age: _age!,
        height: _height,
        weight: _weight,
        targetWeight: _targetWeight,
        primaryGoal: _primaryGoal!,
        workoutFrequency: _workoutFrequency!,
        weeklyGoal: _weeklyGoal,
        dailyCalories: dailyCalories,
        proteinGoal: macros['protein']!,
        carbsGoal: macros['carbs']!,
        fatGoal: macros['fat']!,
        waterGoal: 2000,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      userProfile = userProfile.updateNutritionGoals();

      final _firestoreService = FirestoreService();
      await _firestoreService.createUserProfile(userProfile);
      await Future.delayed(const Duration(seconds: 2));

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => AuthWrapper()));
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentStep = _totalSteps - 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Validation methods
  bool _canProceedFromBasicInfo() {
    return _gender != null && _age != null;
  }

  bool _canProceedFromBodyInfo() {
    return _height > 0 && _weight > 0;
  }

  bool _canProceedFromGoals() {
    return _primaryGoal != null && _targetWeight > 0;
  }

  bool _canProceedFromActivity() {
    return _workoutFrequency != null;
  }

  bool _canProceedFromWeeklyGoal() {
    return _weeklyGoal > 0;
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: SmoothPageIndicator(
        controller: _pageController,
        count: _totalSteps,
        effect: const ExpandingDotsEffect(
          activeDotColor: Colors.black87,
          dotColor: Color(0xFFBBDEFB),
          dotHeight: 8,
          dotWidth: 8,
          spacing: 8,
        ),
        onDotClicked: (index) {
          if (index < _currentStep) {
            setState(() {
              _currentStep = index;
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            });
          }
        },
      ),
    );
  }

  Widget _buildTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle('About You', 'Let\'s start with some basic information'),

          // Gender selection
          Text(
            'Gender',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children:
                _genderOptions.map((gender) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _gender = gender;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _gender == gender
                                  ? Colors.black87
                                  : Colors.white,
                          foregroundColor:
                              _gender == gender
                                  ? Colors.white
                                  : Colors.grey[800],
                          elevation: _gender == gender ? 4 : 1,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color:
                                  _gender == gender
                                      ? Colors.black87
                                      : Colors.grey[300]!,
                            ),
                          ),
                        ),
                        child: Text(gender),
                      ),
                    ),
                  );
                }).toList(),
          ),

          const SizedBox(height: 24),

          // Age input
          Text(
            'Age',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter your age',
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(
                Icons.calendar_today,
                color: Colors.black87,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _age = int.tryParse(value);
              });
            },
          ),

          const SizedBox(height: 48),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canProceedFromBasicInfo() ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(
            'Body Measurements',
            'Help us understand your current physique',
          ),

          // Height slider
          Text(
            'Height (cm)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _height.toInt().toString(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Slider(
            value: _height,
            min: 120,
            max: 220,
            divisions: 100,
            activeColor: Colors.black87,
            inactiveColor: Colors.grey[300],
            thumbColor: Colors.black87,
            onChanged: (value) {
              setState(() {
                _height = value;
              });
            },
          ),

          const SizedBox(height: 24),

          // Weight slider
          Text(
            'Weight (kg)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _weight.toInt().toString(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Slider(
            value: _weight,
            min: 40,
            max: 150,
            divisions: 110,
            activeColor: Colors.black87,
            inactiveColor: Colors.grey[300],
            thumbColor: Colors.black87,
            onChanged: (value) {
              setState(() {
                _weight = value;
              });
            },
          ),

          const SizedBox(height: 48),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.black87),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _canProceedFromBodyInfo() ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle('Your Goals', 'Let us know what you\'re aiming for'),

          // Primary Goal
          Text(
            'What\'s your primary goal?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),

          // Goal selection with icons
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildGoalTile('Lose Weight', Icons.trending_down),
              _buildGoalTile('Maintain Weight', Icons.balance),
              _buildGoalTile('Gain Weight', Icons.trending_up),
              _buildGoalTile('Build Muscle', Icons.fitness_center),
            ],
          ),

          const SizedBox(height: 32),

          // Target Weight slider
          Text(
            'Target Weight (kg)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _targetWeight.toInt().toString(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _targetWeight > _weight
                    ? '(+${(_targetWeight - _weight).toStringAsFixed(1)})'
                    : _targetWeight < _weight
                    ? '(-${(_weight - _targetWeight).toStringAsFixed(1)})'
                    : '(maintain)',
                style: TextStyle(
                  fontSize: 16,
                  color:
                      _targetWeight > _weight
                          ? Colors.green
                          : _targetWeight < _weight
                          ? Colors.orange
                          : Colors.blue,
                ),
              ),
            ],
          ),

          Slider(
            value: _targetWeight,
            min: 40,
            max: 150,
            divisions: 110,
            activeColor: Colors.black87,
            inactiveColor: Colors.grey[300],
            thumbColor: Colors.black87,
            onChanged: (value) {
              setState(() {
                _targetWeight = value;
              });
            },
          ),

          const SizedBox(height: 48),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.black87),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _canProceedFromGoals() ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalTile(String goal, IconData icon) {
    final isSelected = _primaryGoal == goal;

    return GestureDetector(
      onTap: () {
        setState(() {
          _primaryGoal = goal;
        });
      },
      child: Container(
        width: (MediaQuery.of(context).size.width - 60) / 2,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Colors.black87.withOpacity(0.1)
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.black87 : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.black87.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black87 : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              goal,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black87 : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityStep() {
    if (_primaryGoal != "Build Muscle") {
      if (_targetWeight == _weight){
        _primaryGoal = "Maintain Weight";
      }
      else if (_targetWeight > _weight){
        _primaryGoal = "Gain Weight";
      }
      else if (_targetWeight < _weight){
        _primaryGoal = "Lose Weight";
      }
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle('Activity Level', 'Tell us about your exercise habits'),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _workoutOptions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final option = _workoutOptions[index];
              final isSelected = _workoutFrequency == option;
              String description;
              IconData icon;

              switch (index) {
                case 0:
                  description = 'Little to no exercise';
                  icon = Icons.weekend;
                  break;
                case 1:
                  description = 'Light exercise 1-3 days/week';
                  icon = Icons.directions_walk;
                  break;
                case 2:
                  description = 'Moderate exercise 3-5 days/week';
                  icon = Icons.directions_run;
                  break;
                case 3:
                  description = 'Hard exercise 6-7 days/week';
                  icon = Icons.fitness_center;
                  break;
                case 4:
                  description = 'Very intense exercise, physical job';
                  icon = Icons.sports;
                  break;
                default:
                  description = '';
                  icon = Icons.help_outline;
              }

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _workoutFrequency = option;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Colors.black87.withOpacity(0.1)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected
                              ? Colors.black87
                              : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? Colors.black87.withOpacity(0.2)
                                  : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color:
                              isSelected
                                  ? Colors.black87
                                  : Colors.grey[600],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    isSelected
                                        ? Colors.black87
                                        : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.black87,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 48),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.black87),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _canProceedFromActivity() ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyGoalStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(
            'Weekly Goal',
            'Choose a realistic pace for your journey',
          ),

          // Only show if goal is weight loss or gain
          if (_primaryGoal == 'Lose Weight' ||
              _primaryGoal == 'Gain Weight') ...[
            Text(
              _primaryGoal == 'Lose Weight'
                  ? 'How much weight do you want to lose per week?'
                  : 'How much weight do you want to gain per week?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_weeklyGoal.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'per week',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Slider(
              value: _weeklyGoal,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              activeColor: Colors.black87,
              inactiveColor: Colors.grey[300],
              thumbColor: Colors.black87,
              onChanged: (value) {
                setState(() {
                  _weeklyGoal = value;
                });
              },
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _primaryGoal == 'Lose Weight'
                          ? 'Health experts recommend losing 0.5-1 kg per week for sustainable weight loss.'
                          : 'For healthy muscle gain, aim for 0.25-0.5 kg per week with proper nutrition and training.',
                      style: TextStyle(fontSize: 14, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Show this if goal is maintenance
          if (applyFix() && _primaryGoal == 'Maintain Weight' ||
              _primaryGoal == 'Build Muscle') ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green[100]!),
              ),
              child: Column(
                children: [
                  Icon(
                    _primaryGoal == 'Maintain Weight'
                        ? Icons.check_circle
                        : Icons.fitness_center,
                    color: Colors.green,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _primaryGoal == 'Maintain Weight'
                        ? 'You\'ve chosen to maintain your current weight'
                        : 'You\'ve chosen to build muscle',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _primaryGoal == 'Maintain Weight'
                        ? 'We\'ll calculate the perfect calorie balance to keep your weight stable while meeting your nutritional needs.'
                        : 'We\'ll optimize your protein intake and calorie surplus to support muscle growth while minimizing fat gain.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 48),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.black87),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _canProceedFromWeeklyGoal()
                          ? _saveUserDataAndNavigate
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Complete',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinishStep() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F5DC), Color(0xFFE5E5DB)], // Beige gradient
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App Title
              Text(
                'CaloriX',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 30),

              // Custom Loading Indicator
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),
              // Loading Text
              Text(
                'Загружаем ваш путь к здоровью...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5DC),
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F5DC),
        elevation: 0,
        leading:
            _currentStep > 0 && !_isLoading
                ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: _previousStep,
                )
                : null,
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (!_isLoading) _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildBasicInfoStep(),
                _buildBodyInfoStep(),
                _buildGoalsStep(),
                _buildActivityStep(),
                _buildWeeklyGoalStep(),
                _buildFinishStep(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedProgressCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const AnimatedProgressCard({
    Key? key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.color = Colors.black87,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CustomToggleButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onPressed;

  const CustomToggleButton({
    Key? key,
    required this.text,
    required this.isSelected,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black87 : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.black87 : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.black87.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey[800],
          ),
        ),
      ),
    );
  }
}


