import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Sincronizzazione tra box Hive locali e Firestore
class SyncService {
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static Future<void> syncWorkoutHistory(Box<dynamic> historyBox) async {
    if (Firebase.apps.isEmpty) return;
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;

    try {
      final stringifiedData = <String, dynamic>{};
      historyBox.toMap().forEach((key, value) {
        stringifiedData[key.toString()] = value;
      });

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('data')
          .doc('history')
          .set(
        {
          'records': stringifiedData,
          'lastSync': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('SyncService Error [History]: $e');
    }
  }
}
