import 'dart:math' as math;

// Funzioni di geometria per il calcolo degli angoli articolari 2D/3D
class GeometryUtils {
  static double calculateAngleCoords(
    double ax,
    double ay,
    double bx,
    double by,
    double cx,
    double cy,
  ) {
    final radians = math.atan2(cy - by, cx - bx) - math.atan2(ay - by, ax - bx);
    var angle = (radians * 180.0 / math.pi).abs();
    if (angle > 180.0) angle = 360.0 - angle;
    return angle;
  }

  static double calculateAngle3DCoords(
    double ax,
    double ay,
    double az,
    double bx,
    double by,
    double bz,
    double cx,
    double cy,
    double cz,
  ) {
    final vx1 = ax - bx;
    final vy1 = ay - by;
    final vz1 = az - bz;
    final vx2 = cx - bx;
    final vy2 = cy - by;
    final vz2 = cz - bz;
    final dot = (vx1 * vx2) + (vy1 * vy2) + (vz1 * vz2);
    final mag1 = math.sqrt(vx1 * vx1 + vy1 * vy1 + vz1 * vz1);
    final mag2 = math.sqrt(vx2 * vx2 + vy2 * vy2 + vz2 * vz2);
    if (mag1 == 0 || mag2 == 0) return 0;
    final cosTheta = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    return math.acos(cosTheta) * (180.0 / math.pi);
  }
}
