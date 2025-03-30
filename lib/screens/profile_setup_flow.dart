import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../services/nutrition_service.dart';
import 'main_screen.dart';

class AppColors {
  static const Color primary = Color(0xFF000000);
  static const Color secondary = Color(0xFF4A90E2);
  static const Color background = Color(0xFFFAFAFA);
  static const Color card = Colors.white;
  static const Color text = Color(0xFF333333);
  static const Color textLight = Color(0xFF777777);
  static const Color success = Color(0xFF4CD964);
}

class ProfileSetupFlow extends StatefulWidget {
  @override
  _ProfileSetupFlowState createState() => _ProfileSetupFlowState();
}

class _ProfileSetupFlowState extends State<ProfileSetupFlow>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  int _currentStep = 0;
  int _totalSteps = 7;

  String? _gender;
  String? _workoutFrequency;
  String? _primaryGoal;
  int _age = 20;
  double _height = 177;
  double _weight = 60;
  double _targetWeight = 60;
  double _weeklyGoal = 1.0;
  bool _isLoading = false;

  bool get _currentPageHasSelection {
    switch (_currentStep) {
      case 0:
        return _gender != null;
      case 1:
        return _workoutFrequency != null;
      case 2:
        return _age != null;
      case 3:
      case 4:
      case 5:
      case 6:
        return true;
      default:
        return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (!_currentPageHasSelection) {
      HapticFeedback.mediumImpact();
      _animationController
          .forward()
          .then((_) => _animationController.reverse());
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    } else {
      _saveUserDataAndNavigate();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.background, Colors.white],
              stops: [0.0, 0.4],
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _currentStep > 0
                        ? IconButton(
                            icon: Icon(Icons.arrow_back_ios_new,
                                color: AppColors.text),
                            onPressed: _previousStep,
                          )
                        : SizedBox(width: 48),
                    Expanded(
                      child: Center(
                        child: _buildProgressIndicator(),
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    _buildGenderStep(),
                    _buildWorkoutFrequencyStep(),
                    _buildAgeStep(),
                    _buildHeightStep(),
                    _buildWeightStep(),
                    _buildTargetWeightStep(),
                    _buildWeeklyGoalStep(),
                    _buildLoadingScreen(),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                        _animationController.value *
                            10 *
                            ((_animationController.value * 10).floor() % 2 == 0
                                ? 1
                                : -1),
                        0),
                    child: child,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Continue',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_totalSteps, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          width: index == _currentStep ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: index <= _currentStep
                ? AppColors.primary
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildGenderStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40),
          Text(
            "Tell us about yourself",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: 16),
          Text(
            "Select your gender",
            style: TextStyle(
              fontSize: 20,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 40),
          _buildGenderOption('Male', Icons.male, _gender == 'male'),
          SizedBox(height: 20),
          _buildGenderOption('Female', Icons.female, _gender == 'female'),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String gender, IconData icon, bool isSelected) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                )
              ]
            : [],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _gender = gender.toLowerCase();
          });
          HapticFeedback.lightImpact();
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                gender,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.text,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutFrequencyStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40),
          Text(
            "Your activity level",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: 16),
          Text(
            "How often do you workout?",
            style: TextStyle(
              fontSize: 20,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 40),
          _buildFrequencyOption('Beginner', '0-2 workouts a week',
              Icons.directions_walk, '😌', 'beginner'),
          SizedBox(height: 20),
          _buildFrequencyOption('Intermediate', '3-5 workouts a week',
              Icons.directions_run, '💪', 'intermediate'),
          SizedBox(height: 20),
          _buildFrequencyOption('Advanced', '6+ workouts a week',
              Icons.fitness_center, '🔥', 'advanced'),
        ],
      ),
    );
  }

  Widget _buildPrimaryGoalStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40),
          Text(
            "Your fitness journey",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: 16),
          Text(
            "What's your primary goal?",
            style: TextStyle(
              fontSize: 20,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 40),
          _buildGoalOption(
              'Lose Weight', Icons.trending_down, '🔥', 'lose_weight'),
          SizedBox(height: 20),
          _buildGoalOption(
              'Maintain Weight', Icons.balance, '⚖️', 'maintain_weight'),
          SizedBox(height: 20),
          _buildGoalOption(
              'Gain Weight', Icons.trending_up, '💪', 'gain_weight'),
        ],
      ),
    );
  }

  Widget _buildGoalOption(String title, IconData icon, String emoji,
      String value) {
    final isSelected = _primaryGoal == value;

    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ]
            : [],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _primaryGoal = value;
          });
          HapticFeedback.lightImpact();
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight
                          .w500,
                      color: isSelected ? AppColors.primary : AppColors.text,
                    ),
                  ),
                  // if (isSelected)
                  //   Padding(
                  //     padding: const EdgeInsets.only(top: 4.0),
                  //   ),
                ],
              ),
            ),
            Text(
              emoji,
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyOption(String title, String subtitle, IconData icon,
      String emoji, String value) {
    final isSelected = _workoutFrequency == value;

    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                )
              ]
            : [],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _workoutFrequency = value;
          });
          HapticFeedback.lightImpact();
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.text,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              emoji,
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeightStep() {
    final double minHeight = 140.0;
    final double maxHeight = 220.0;
    final int divisions = 80;

    if (_height < minHeight) _height = minHeight;
    if (_height > maxHeight) _height = maxHeight;

    String displayHeight;
    String unitText;

    displayHeight = '${_height.toInt()}';
    unitText = 'cm';

    double personPosition =
        180 - (((_height - minHeight) / (maxHeight - minHeight)) * 180);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            "Body measurements",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "What is your height?",
            style: TextStyle(
              fontSize: 20,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.8),
                    AppColors.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    displayHeight,
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (unitText.isNotEmpty) const SizedBox(width: 8),
                  if (unitText.isNotEmpty)
                    Text(
                      unitText,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 220,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: 24,
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary.withOpacity(0.3),
                            AppColors.primary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    ...List.generate(6, (index) {
                      return Positioned(
                        left: 30,
                        bottom: (180 / 5) * index,
                        child: Text(
                          '${(minHeight + ((maxHeight - minHeight) / 5) * (5 - index)).toInt()}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textLight,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 8,
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: Colors.grey.shade200,
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 14,
                    elevation: 6,
                  ),
                  overlayColor: AppColors.primary.withOpacity(0.2),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 28),
                ),
                child: SizedBox(
                  height: 220,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: SizedBox(
                      width: 180,
                      child: Slider(
                        value: _height.clamp(minHeight, maxHeight),
                        min: minHeight,
                        max: maxHeight,
                        divisions: divisions,
                        onChanged: (value) {
                          setState(() {
                            _height = value;
                          });
                          if ((value * 10) % 10 == 0) {
                            HapticFeedback.selectionClick();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${minHeight.toInt()} cm',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${maxHeight.toInt()} cm',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Weight Selection Step
  Widget _buildWeightStep() {
    final double minWeight = 40.0;
    final double maxWeight = 130.0;
    final int divisions = 90;

    if (_weight < minWeight) _weight = minWeight;
    if (_weight > maxWeight) _weight = maxWeight;

    String displayWeight = '${_weight.toInt()}';
    String unitText = 'kg';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            "Body Profile",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "What is your current weight?",
            style: TextStyle(
              fontSize: 20,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 50),

          // Weight display card
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.9),
                    AppColors.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    displayWeight,
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    unitText,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 60),

          // Slider for weight selection
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 10,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 16,
                elevation: 6,
              ),
              overlayColor: AppColors.primary.withOpacity(0.2),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
            ),
            child: Slider(
              value: _weight.clamp(minWeight, maxWeight),
              min: minWeight,
              max: maxWeight,
              divisions: divisions,
              onChanged: (value) {
                setState(() {
                  _weight = value;
                });
                if ((value * 10) % 10 == 0) {
                  HapticFeedback.selectionClick();
                }
              },
            ),
          ),

          const SizedBox(height: 18),

          // Min/Max weight labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${minWeight.toInt()} $unitText',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${maxWeight.toInt()} $unitText',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          // Info card
          _buildWeightContext(),
        ],
      ),
    );
  }

// Weight context info card
  Widget _buildWeightContext() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.info_outline,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Weight data helps us personalize your calorie goals. "
              "You'll be able to track your progress over time.",
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetWeightStep() {
    // Determine if losing or gaining weight
    bool isLosing = _targetWeight < _weight;
    IconData trendIcon = isLosing ? Icons.trending_down : Icons.trending_up;
    Color trendColor = isLosing ? Colors.green.shade600 : Colors.blue.shade600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            "Goal Setting",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "What weight would you like to reach?",
            style: TextStyle(
              fontSize: 20,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 50),

          // Target weight display
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    trendColor.withOpacity(0.8),
                    trendColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: trendColor.withOpacity(0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${_targetWeight.toInt()}',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'kg',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Current vs Target comparison
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    children: [
                      Text(
                        'Current',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_weight.toInt()} kg',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: trendColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      trendIcon,
                      size: 32,
                      color: trendColor,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        'Target',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: trendColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_targetWeight.toInt()} kg',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: trendColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Target weight slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 10,
              activeTrackColor: trendColor,
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 16,
                elevation: 4,
              ),
              overlayColor: trendColor.withOpacity(0.2),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
            ),
            child: Slider(
              value: _targetWeight,
              min: 40,
              max: 120,
              divisions: 80,
              onChanged: (value) {
                setState(() {
                  _targetWeight = value;
                });
                if ((value * 10) % 10 == 0) {
                  HapticFeedback.selectionClick();
                }
              },
            ),
          ),

          const SizedBox(height: 18),

          // Min/Max labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '40 kg',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '120 kg',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: trendColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.tips_and_updates_outlined,
                    color: trendColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    isLosing
                        ? "Healthy weight loss is typically 0.5-1 kg per week. We'll help you set realistic goals."
                        : "Healthy weight gain is typically 0.25-0.5 kg per week. We'll help you set realistic goals.",
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Add this additional method for age selection
  Widget _buildAgeStep() {
    int minAge = 13;
    int maxAge = 80;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            "About You",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "How old are you?",
            style: TextStyle(
              fontSize: 20,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 50),

          // Age display
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.9),
                    AppColors.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    "${_age}",
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "years",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 60),
          // Age slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 10,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 16,
                elevation: 6,
              ),
              overlayColor: AppColors.primary.withOpacity(0.2),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
            ),
            child: Slider(
              value: _age.toDouble(),
              min: minAge.toDouble(),
              max: maxAge.toDouble(),
              divisions: maxAge - minAge,
              onChanged: (value) {
                setState(() {
                  _age = value.toInt();
                });
                HapticFeedback.selectionClick();
              },
            ),
          ),

          const SizedBox(height: 18),

          // Min/Max age labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$minAge yrs',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$maxAge yrs',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "Your age helps us calculate your basal metabolic rate and daily calorie needs more accurately.",
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyGoalStep() {
    String goalTypeText = "";
    Color goalColor = AppColors.primary;

    // Determine goal type and color
    goalTypeText = "Weekly activity goal";
    goalColor = Color(0xFF2196F3); // Bright blue

    final goalOptions = [
      {
        'value': 0.1,
        'emoji': '🍐',
        'text': 'Very gentle, slow progress',
      },
      {
        'value': 0.5,
        'emoji': '🍉',
        'text': 'Moderate, balanced pace',
      },
      {
        'value': 0.8,
        'emoji': '🍎',
        'text': 'Standard recommended pace',
      },
      {
        'value': 1.0,
        'emoji': '🥑',
        'text': 'Ambitious, requires discipline',
      },
    ];

    // Calculate estimated time to goal
    int weeksToGoal = (_targetWeight - _weight).abs() ~/ _weeklyGoal;
    String timeEstimate = "$weeksToGoal weeks";

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF9F9F2)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "How much weight do you\nwant to lose each week?",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: goalColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  "You will reach your goal in $timeEstimate",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: goalColor,
                  ),
                ),
              ),
              SizedBox(height: 32),
              Expanded(
                child: ListView.builder(
                  itemCount: goalOptions.length,
                  padding: EdgeInsets.zero,
                  physics: BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final option = goalOptions[index];
                    final isSelected = (_weeklyGoal * 10).round() ==
                        ((option['value'] as double) * 10).round();

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _weeklyGoal = option['value'] as double;
                        });
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? goalColor : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Text(
                              option['emoji'] as String,
                              style: TextStyle(fontSize: 36),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${option['value']} kg",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? goalColor
                                          : Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    option['text'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: isSelected ? goalColor : Colors.grey,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      padding: EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Setting up your personalized plan",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            "We're calculating your nutrition needs and preparing your fitness journey",
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeWidth: 6,
          ),
        ],
      ),
    );
  }

  Future<void> _saveUserDataAndNavigate() async {
    setState(() {
      _isLoading = true;
      _pageController.animateToPage(
        _totalSteps,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception("No authenticated user found");
      }
      final age = _age;

      final nutritionService = NutritionService();
      final dailyCalories = nutritionService.calculateDailyCalories(
        gender: _gender!,
        age: age,
        height: _height,
        weight: _weight,
        activityLevel: _workoutFrequency!,
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
      await _firestoreService.createUserProfile(userProfile);
      await Future.delayed(Duration(seconds: 2));

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MainScreen(),
        ),
      );
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
}
