import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_profile.dart'; // Adjust import path as needed

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _userProfilesCollection =>
      _firestore.collection('users');

  // Create a new user profile
  Future<UserProfile> createUserProfile(UserProfile userProfile) async {
    try {
      // Ensure the user profile has the current user's ID
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Ensure userId matches the current authenticated user
      final profileToSave = userProfile.copyWith(
          userId: currentUser.uid,
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now()
      );

      // Calculate initial nutrition goals
      final updatedProfile = profileToSave.updateNutritionGoals();

      // Save to Firestore
      await _userProfilesCollection.doc(currentUser.uid).set(
          updatedProfile.toMap(),
          SetOptions(merge: true)
      );

      return updatedProfile;
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }

  // Update existing user profile
  Future<UserProfile> updateUserProfile({
    required Map<String, dynamic> updates,
    bool recalculateGoals = true,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Fetch current profile
      final docSnapshot = await _userProfilesCollection.doc(currentUser.uid).get();

      if (!docSnapshot.exists) {
        throw Exception('User profile not found');
      }

      // Convert existing data to UserProfile
      UserProfile existingProfile = UserProfile.fromMap(
          docSnapshot.data() as Map<String, dynamic>
      );

      // Create an updated profile using individual parameters
      UserProfile updatedProfile = existingProfile.copyWith(
        userId: updates['userId'] ?? existingProfile.userId,
        email: updates['email'] ?? existingProfile.email,
        displayName: updates['displayName'] ?? existingProfile.displayName,
        gender: updates['gender'] ?? existingProfile.gender,
        age: updates['age'] ?? existingProfile.age,
        height: updates['height'] ?? existingProfile.height,
        weight: updates['weight'] ?? existingProfile.weight,
        targetWeight: updates['targetWeight'] ?? existingProfile.targetWeight,
        primaryGoal: updates['primaryGoal'] ?? existingProfile.primaryGoal,
        workoutFrequency: updates['workoutFrequency'] ?? existingProfile.workoutFrequency,
        weeklyGoal: updates['weeklyGoal'] ?? existingProfile.weeklyGoal,
        dailyCalories: updates['dailyCalories'] ?? existingProfile.dailyCalories,
        proteinGoal: updates['proteinGoal'] ?? existingProfile.proteinGoal,
        carbsGoal: updates['carbsGoal'] ?? existingProfile.carbsGoal,
        fatGoal: updates['fatGoal'] ?? existingProfile.fatGoal,
        waterGoal: updates['waterGoal'] ?? existingProfile.waterGoal,
        lastUpdated: DateTime.now(),
      );

      // Optionally recalculate nutrition goals
      if (recalculateGoals) {
        updatedProfile = updatedProfile.updateNutritionGoals();
      }

      // Save to Firestore
      await _userProfilesCollection.doc(currentUser.uid).update(
          updatedProfile.toMap()
      );

      return updatedProfile;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  // Retrieve user profile
  Future<UserProfile?> getUserProfile() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return null;
      }

      final docSnapshot = await _userProfilesCollection.doc(currentUser.uid).get();

      if (!docSnapshot.exists) {
        return null;
      }

      return UserProfile.fromMap(
          docSnapshot.data() as Map<String, dynamic>
      );
    } catch (e) {
      debugPrint('Error retrieving user profile: $e');
      return null;
    }
  }

  // Stream user profile for real-time updates
  Stream<UserProfile?> getUserProfileStream() {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return Stream.value(null);
      }

      return _userProfilesCollection
          .doc(currentUser.uid)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) return null;
        return UserProfile.fromMap(
            snapshot.data() as Map<String, dynamic>
        );
      });
    } catch (e) {
      debugPrint('Error in user profile stream: $e');
      return Stream.value(null);
    }
  }

  // Delete user profile
  Future<void> deleteUserProfile() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      await _userProfilesCollection.doc(currentUser.uid).delete();
    } catch (e) {
      debugPrint('Error deleting user profile: $e');
      rethrow;
    }
  }
}