import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/log_item.dart';
import '../models/macro_item.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../services/logs_notifier.dart';
import '../widgets/add_log_widget.dart';
import '../widgets/calories_card.dart';
import '../widgets/date_selector.dart';
import '../widgets/log_list.dart';
import '../widgets/macro_breakdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  DateTime selectedDate = DateTime.now();
  final List<String> weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  UserProfile? userProfile;

  @override
  void initState() {
    super.initState();
    ref.read(logsProvider.notifier).loadLogsFromFirebase(selectedDate);
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final firestoreService = FirestoreService();
    final profile = await firestoreService.getUserProfile();

    setState(() {
      userProfile = profile;
    });
  }

  double calculateCaloriesLeft(List<LogItem> logs) {
    final dailyCalorieGoal = userProfile?.dailyCalories.toDouble() ?? 2500.0;
    final totalConsumedCalories = logs.fold(0, (total, log) => total + log.calories.round());
    return dailyCalorieGoal - totalConsumedCalories;
  }

  List<MacroItem> calculateMacroBreakdown(List<LogItem> logs) {
    double protein = 0, carbs = 0, fat = 0;

    for (var log in logs) {
      if (log.macros != null) {
        for (var macro in log.macros!) {
          switch (macro.icon) {
            case '🍗':
              protein += macro.value;
              break;
            case '🍞':
              carbs += macro.value;
              break;
            case '🧀':
              fat += macro.value;
              break;
          }
        }
      }
    }
    return [
      MacroItem(
        name: "Protein",
        left: (userProfile?.proteinGoal ?? 100) - protein.round(),
        total: userProfile?.proteinGoal ?? 100,
        icon: FontAwesomeIcons.drumstickBite,
        color: Color(0xFF8D6E63),
      ),
      MacroItem(
        name: "Carbs",
        left: (userProfile?.carbsGoal ?? 300) - carbs.round(),
        total: userProfile?.carbsGoal ?? 300,
        icon: FontAwesomeIcons.cookieBite,
        color: Color(0xFF689F38),
      ),
      MacroItem(
        name: "Fat",
        left: (userProfile?.fatGoal ?? 50) - fat.round(),
        total: userProfile?.fatGoal ?? 50,
        icon: FontAwesomeIcons.droplet,
        color: Color(0xFFFFA000),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(logsProvider);
    final totalCalories = userProfile?.dailyCalories.toDouble() ?? 2500.0;
    final caloriesLeft = calculateCaloriesLeft(logs);
    final macros = calculateMacroBreakdown(logs);

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
            children: [
              // App Bar and Date Selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CaloriX',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/profile');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(Icons.person_outline, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),

              // Date Selector Widget
              // DateSelector(
              //   selectedDate: selectedDate,
              //   weekdays: weekdays,
              //   onDateSelected: (date) {
              //     setState(() {
              //       selectedDate = date;
              //     });
              //     ref.read(logsProvider.notifier).loadLogsFromFirebase(date);
              //   },
              // ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()
                  ),
                  child: Column(
                    children: [
                      // Calories Card Widget
                      CaloriesCard(
                        caloriesLeft: caloriesLeft,
                        caloriesTotal: userProfile?.dailyCalories.toDouble() ?? 2500.0,
                      ),

                      // Macro Breakdown Widget
                      MacroBreakdown(macros: macros),

                      // Meal Log List Widget
                      LogList(logs: logs),

                      SizedBox(height: 200),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0, left: 30),
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              isScrollControlled: false,
              builder: (context) => AddLogWidget(),
            );
          },
          backgroundColor: Colors.black,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}