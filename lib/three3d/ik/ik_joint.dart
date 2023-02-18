import 'package:three_dart/three_dart.dart';
import 'package:three_dart/three3d/ik/ik_utils.dart' as utils;

/// A class for a joint.
class IKJoint {
  static final Y_AXIS = Vector3(0, 1, 0);

  Bone bone;
  List<IKBallConstraint>? constraints;

  double _distance = 0;

  Vector3 _originalDirection = Vector3();
  final Vector3 _direction = Vector3();
  final Vector3 _worldPosition = Vector3();

  bool _isSubBase = false;
  List<Vector3>? _subBasePositions;

  /// @param {THREE.Bone} bone
  /// @param {Object} config
  /// @param {Array<IKConstraint>} [config.constraints]
  IKJoint(this.bone, {this.constraints}) {
    constraints ??= [];
    updateWorldPosition();
  }

  /// @private
  setIsSubBase() {
    _isSubBase = true;
    _subBasePositions = [];
  }

  bool get isSubBase => _isSubBase;

  addSubBasePosition(worldPosition) {
    _subBasePositions!.add(worldPosition);
  }

  /// Consumes the stored sub base positions and apply it as this
  /// joint's world position, clearing the sub base positions.
  ///
  /// @private
  applySubBasePositions() {
    if (_subBasePositions == null || _subBasePositions!.isEmpty) {
      return;
    }
    utils.getCentroid(_subBasePositions!, _worldPosition);
    _subBasePositions!.clear();
  }

  /// @private
  applyConstraints() {
    if (constraints == null) {
      return;
    }

    bool constraintApplied = false;
    for (final constraint in constraints!) {
      final applied = constraint.apply(this);
      constraintApplied = constraintApplied || applied;
    }
    return constraintApplied;
  }

  /// Set the distance.
  /// @private
  /// @param {number} distance
  setDistance(double distance) {
    _distance = distance;
  }

  double get distance => _distance;

  Vector3 get direction => _direction;

  setDirection(Vector3 direction) {
    _direction.copy(direction);
  }

  setOriginalDirection(Vector3 direction) {
    _originalDirection = direction;
  }

  updateMatrixWorld() {
    bone.updateMatrixWorld(true);
  }

  /// @return {THREE.Vector3}
  Vector3 getWorldPosition() {
    return _worldPosition;
  }

  Vector3 getWorldDirection(IKJoint joint) {
    return Vector3()
        .subVectors(getWorldPosition(), joint.getWorldPosition())
        .normalize();
  }

  updateWorldPosition() {
    utils.getWorldPosition(bone, _worldPosition);
  }

  setWorldPosition(position) {
    _worldPosition.copy(position);
  }

  Vector3 localToWorldDirection(Vector3 direction) {
    if (bone.parent != null) {
      final parentMat = bone.parent!.matrixWorld;
      direction.transformDirection(parentMat);
    }
    return direction;
  }

  /// @private
  Vector3 worldToLocalDirection(Vector3 direction) {
    if (bone.parent != null) {
      final inverseParentMat =
          Matrix4().copy(bone.parent!.matrixWorld).invert();
      direction.transformDirection(inverseParentMat);
    }
    return direction;
  }

  applyWorldPosition() {
    final direction = Vector3().copy(_direction);
    final position = Vector3().copy(getWorldPosition());

    final parent = bone.parent;
    if (parent != null) {
      updateMatrixWorld();

      final inverseParentMat = Matrix4().copy(parent.matrixWorld).invert();
      utils.transformPoint(position, inverseParentMat, position);
      bone.position.copy(position);

      updateMatrixWorld();

      direction.transformDirection(inverseParentMat);

      utils.setQuaternionFromDirection(direction, Y_AXIS, bone.quaternion);
    } else {
      bone.position.copy(position);
    }

    // Update the world matrix so the next joint can properly transform
    // with this world matrix
    bone.updateMatrix();
    updateMatrixWorld();
  }

  /// @param {IKJoint|THREE.Vector3}
  /// @return {THREE.Vector3}
  double getWorldDistance(joint) {
    return _worldPosition.distanceTo(joint is IKJoint
        ? joint.getWorldPosition()
        : utils.getWorldPosition(joint, Vector3()));
  }
}
