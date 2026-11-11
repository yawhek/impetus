import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Libreria di funzioni pure per il calcolo geometrico e cinematico dei landmark scheletrici.
///
/// Implementa i metodi trigonometrici fondamentali descritti nella tesi per
/// la determinazione dell'angolo del gomito (estensione pugno) e del ginocchio (caricamento calcio).
class GeometryUtils {
  /// Calcola l'angolo planare 2D compreso tra tre punti articolari (p1 -> p2 -> p3).
  ///
  /// Utilizza l'arcotangente a due argomenti (atan2) per gestire i quattro quadranti
  /// ed evitare la divisione per zero tipica della pendenza euclidea m = dy/dx:
  /// θ = |atan2(y3 - y2, x3 - x2) - atan2(y1 - y2, x1 - x2)|
  static double calculateAngle(
    PoseLandmark p1,
    PoseLandmark p2,
    PoseLandmark p3,
  ) {
    final radians = math.atan2(p3.y - p2.y, p3.x - p2.x) -
        math.atan2(p1.y - p2.y, p1.x - p2.x);
    var angle = (radians * 180.0 / math.pi).abs();
    if (angle > 180.0) angle = 360.0 - angle;
    return angle;
  }

  /// Calcola l'angolo 3D nello spazio euclideo formato da tre landmark (vertice in p2).
  ///
  /// Determina i vettori direzionali a = (p1 - p2) e b = (p3 - p2) e applica la
  /// formula del prodotto scalare normalizzato:
  /// cos(θ) = (a · b) / (||a|| * ||b||)
  ///
  /// Include il clamping su [-1.0, 1.0] per prevenire valori NaN generati da
  /// imprecisioni di arrotondamento floating-point prima dell'arcocoseno.
  static double calculateAngle3D(
    PoseLandmark p1,
    PoseLandmark p2,
    PoseLandmark p3,
  ) {
    final ax = p1.x - p2.x;
    final ay = p1.y - p2.y;
    final az = p1.z - p2.z;

    final bx = p3.x - p2.x;
    final by = p3.y - p2.y;
    final bz = p3.z - p2.z;

    final dotProduct = (ax * bx) + (ay * by) + (az * bz);
    final magA = math.sqrt(ax * ax + ay * ay + az * az);
    final magB = math.sqrt(bx * bx + by * by + bz * bz);

    if (magA == 0 || magB == 0) return 0;

    var cosTheta = dotProduct / (magA * magB);
    cosTheta = cosTheta.clamp(-1.0, 1.0);

    return math.acos(cosTheta) * (180.0 / math.pi);
  }
}
