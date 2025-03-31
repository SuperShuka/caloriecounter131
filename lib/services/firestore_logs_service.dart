import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/log_item.dart';

class FirebaseLogsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> addLogItem(LogItem logItem) async {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('logs')
          .add({
            'name': logItem.name,
            'calories': logItem.calories,
            'timestamp': logItem.timestamp,
            'type': logItem.type.toString(),
            'macros':
                logItem.macros
                    ?.map((macro) => {'icon': macro.icon, 'value': macro.value})
                    .toList(),
            'weight': logItem.weight,
          });
    } catch (e) {
      print('Error adding log item: $e');
      rethrow;
    }
  }

  Stream<List<LogItem>> getLogs(DateTime date) {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('logs')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: DateTime(date.year, date.month, date.day),
          isLessThan: DateTime(date.year, date.month, date.day + 1),
        )
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                return LogItem(
                  name: data['name'],
                  calories: data['calories'],
                  timestamp: (data['timestamp'] as Timestamp).toDate(),
                  type: LogItemType.values.firstWhere(
                    (e) => e.toString() == data['type'],
                  ),
                  macros:
                      (data['macros'] as List?)
                          ?.map<MacroDetail>(
                            (m) =>
                                MacroDetail(icon: m['icon'], value: m['value']),
                          )
                          .toList(),
                  weight: data['weight'],
                );
              }).toList(),
        );
  }

  Future<void> syncLogsToFirebase(List<LogItem> logs) async {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    final batch = _firestore.batch();
    final logsRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('logs');

    final querySnapshot = await logsRef.get();
    for (var doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }

    for (var log in logs) {
      final docRef = logsRef.doc();
      batch.set(docRef, {
        'name': log.name,
        'calories': log.calories,
        'timestamp': log.timestamp,
        'type': log.type.toString(),
        'macros':
            log.macros
                ?.map((macro) => {'icon': macro.icon, 'value': macro.value})
                .toList(),
        'weight': log.weight,
      });
    }

    await batch.commit();
  }

  Future<void> deleteLogItem(LogItem logItem) async {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    try {
      // Query to find the specific log item
      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('logs')
              .where('name', isEqualTo: logItem.name)
              .where('calories', isEqualTo: logItem.calories)
              .where('timestamp', isEqualTo: logItem.timestamp)
              .get();

      // Delete all matching documents
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error deleting log item: $e');
      rethrow;
    }
  }

  Future<void> updateLogItem(LogItem updatedLogItem) async {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('logs')
              .where('timestamp', isEqualTo: updatedLogItem.timestamp)
              .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.update({
          'name': updatedLogItem.name,
          'calories': updatedLogItem.calories,
          'type': updatedLogItem.type.toString(),
          'macros':
              updatedLogItem.macros
                  ?.map((macro) => {'icon': macro.icon, 'value': macro.value})
                  .toList(),
          'weight': updatedLogItem.weight,
        });
      }
    } catch (e) {
      print('Error updating log item: $e');
      rethrow;
    }
  }
}
