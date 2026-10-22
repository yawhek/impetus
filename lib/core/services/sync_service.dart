import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum SyncStatus { success, failed, notAuthenticated }

/// Servizio di sincronizzazione bidirezionale: Hive (Locale) <-> Firestore (Cloud).
class SyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sincronizzazione completa di tutti i box essenziali
  static Future<void> syncAll(
    Box<dynamic> profileBox,
    Box<dynamic> historyBox,
  ) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;

    try {
      await Future.wait([
        syncProfile(profileBox),
        syncWorkoutHistory(historyBox),
      ]);
    } catch (e) {
      debugPrint('SyncService Error [syncAll]: $e');
    }
  }

  /// Sincronizza il profilo utente e parametri biometrici
  static Future<SyncStatus> syncProfile(Box<dynamic> profileBox) async {
    final user = _auth.currentUser;
    if (user == null) return SyncStatus.notAuthenticated;

    try {
      final data = Map<String, dynamic>.from(profileBox.toMap());
      await _firestore.collection('users').doc(user.uid).set(
        {
          ...data,
          'lastSync': FieldValue.serverTimestamp(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
      return SyncStatus.success;
    } catch (e) {
      debugPrint('SyncService Error [Profile]: $e');
      return SyncStatus.failed;
    }
  }

  /// Sincronizza lo storico sessioni di allenamento e peso
  static Future<SyncStatus> syncWorkoutHistory(Box<dynamic> historyBox) async {
    final user = _auth.currentUser;
    if (user == null) return SyncStatus.notAuthenticated;

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
      return SyncStatus.success;
    } catch (e) {
      debugPrint('SyncService Error [History]: $e');
      return SyncStatus.failed;
    }
  }

  /// Recupera i dati da Firestore e ripopola i box locali Hive (Boot Sync)
  static Future<String> fetchAllFromFirestore(
    Box<dynamic> profileBox,
    Box<dynamic> historyBox,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return 'ERRORE: Utente non loggato.';
    if (user.isAnonymous) return 'GUEST: Sincronizzazione non necessaria.';

    try {
      var count = 0;

      // 1. Download Profilo
      final profileDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (profileDoc.exists && profileDoc.data() != null) {
        final profileData = _sanitizeFirestoreData(profileDoc.data()!);
        profileData.remove('lastSync');
        profileData.remove('updatedAt');

        await profileBox.clear();
        await profileBox.putAll(profileData);
        await profileBox.flush();
        count++;
      }

      // 2. Download Storico Allenamenti
      final historyDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('data')
          .doc('history')
          .get();
      if (historyDoc.exists && historyDoc.data() != null) {
        final docData = historyDoc.data()!;
        if (docData['records'] != null) {
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

  /// Normalizza i dati Firestore (Timestamp, GeoPoint) per la compatibilità con Hive
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
    } else if (value is GeoPoint) {
      return {'latitude': value.latitude, 'longitude': value.longitude};
    } else if (value is Map) {
      return _sanitizeFirestoreData(Map<String, dynamic>.from(value));
    } else if (value is List) {
      return value.map(_sanitizeValue).toList();
    }
    return value;
  }
}
