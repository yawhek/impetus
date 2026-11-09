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

  static Future<String> fetchAllFromFirestore(
    Box<dynamic> profileBox,
    Box<dynamic> historyBox,
  ) async {
    if (Firebase.apps.isEmpty) return 'Firebase non configurato.';
    final user = _auth.currentUser;
    if (user == null) return 'ERRORE: Utente non loggato.';
    if (user.isAnonymous) return 'GUEST: Sincronizzazione non necessaria.';

    final uid = user.uid;

    try {
      var count = 0;

      final profileDoc = await _firestore.collection('users').doc(uid).get();
      if (_auth.currentUser?.uid != uid) {
        return 'Sincronizzazione annullata per cambio account.';
      }
      if (profileDoc.exists && profileDoc.data() != null) {
        final profileData = _sanitizeFirestoreData(profileDoc.data()!);
        profileData.remove('lastSync');
        profileData.remove('updatedAt');

        await profileBox.clear();
        await profileBox.putAll(profileData);
        await profileBox.flush();
        count++;
      }

      final historyDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('data')
          .doc('history')
          .get();
      if (_auth.currentUser?.uid != uid) {
        return 'Sincronizzazione annullata per cambio account.';
      }
      if (historyDoc.exists && historyDoc.data() != null) {
        final docData = historyDoc.data()!;
        if (docData['records'] is Map) {
          final historyData = _sanitizeFirestoreData(
            Map<String, dynamic>.from(docData['records'] as Map),
          );
          await historyBox.clear();
          await historyBox.putAll(historyData);
          await historyBox.flush();
          count++;
        }
      }

      return count > 0
          ? 'Successo: $count moduli recuperati.'
          : 'Nessun dato remoto presente.';
    } catch (e) {
      debugPrint('SyncService Fetch Error: $e');
      return 'Errore recupero cloud: $e';
    }
  }

  static Future<void> clearLocalUserData(
    Box<dynamic> profileBox,
    Box<dynamic> historyBox,
  ) async {
    if (profileBox.isOpen) {
      await profileBox.clear();
      await profileBox.flush();
    }
    if (historyBox.isOpen) {
      await historyBox.clear();
      await historyBox.flush();
    }
  }

  static Map<String, dynamic> _sanitizeFirestoreData(
      Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    data.forEach((key, value) {
      sanitized[key] = _sanitizeValue(value);
    });
    return sanitized;
  }

  static dynamic _sanitizeValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    } else if (value is DateTime) {
      return value.toIso8601String();
    } else if (value is Map) {
      return _sanitizeFirestoreData(Map<String, dynamic>.from(value));
    } else if (value is List) {
      return value.map(_sanitizeValue).toList();
    }
    return value;
  }
}
