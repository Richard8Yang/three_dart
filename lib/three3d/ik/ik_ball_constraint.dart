import 'package:three_dart/three_dart.dart';

/// A class for a constraint.
class IKBallConstraint {
  static final Z_AXIS = Vector3(0, 0, 1);
  static final DEG2RAD = Math.pi / 180.0;
  static final RAD2DEG = 180.0 / Math.pi;

  double angle;

  /// Pass in an angle value in degrees.
  ///
  /// @param {number} angle
  IKBallConstraint(this.angle);

  /// Applies a constraint to passed in IKJoint, updating
  /// its direction if necessary. Returns a boolean indicating
  /// if the constraint was applied or not.
  ///
  /// @param {IKJoint} joint
  /// @return {boolean}
  apply(IKJoint joint) {
    // Get direction of joint and parent in world space
    final direction = Vector3().copy(joint.direction);
    final parentDirection =
        joint.localToWorldDirection(Vector3().copy(Z_AXIS)).normalize();

    // Find the current angle between them
    final currentAngle = direction.angleTo(parentDirection) * RAD2DEG;

    if ((angle / 2) < currentAngle) {
      direction.normalize();
      // Find the correction axis and rotate around that point to the
      // largest allowed angle
      final correctionAxis =
          Vector3().crossVectors(parentDirection, direction).normalize();

      parentDirection.applyAxisAngle(correctionAxis, angle * DEG2RAD * 0.5);
      joint.setDirection(parentDirection);
      return true;
    }

    return false;
  }
}
