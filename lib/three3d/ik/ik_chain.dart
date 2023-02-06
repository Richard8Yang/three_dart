import 'package:three_dart/three_dart.dart';

/// Class representing an IK chain, comprising multiple IKJoints.
class IKChain {
  double totalLengths = 0;
  IKJoint? base;
  IKJoint? effector;
  IKJoint? effectorIndex;
  dynamic target;
  Map chains = {};
  List<IKJoint>? joints;

  /// THREE.Vector3 world position of base node
  Vector3? origin;

  int iterations = 100;
  double tolerance = 0.01;

  int _depth = -1;
  final _targetPosition = Vector3();

  /// Add an IKJoint to the end of this chain.
  ///
  /// @param {IKJoint/Bone} joint
  /// @param {Object} config
  /// @param {THREE.Object3D} [config.target]
  add(dynamic joint, {Object3D? targetObj}) {
    if (effector != null) {
      print('Cannot add additional joints to a chain with an end effector.');
      return this;
    }

    if (joint is! IKJoint) {
      if (joint is Bone) {
        joint = IKJoint(joint);
      } else {
        print(
            'Invalid joint in an IKChain. Must be an IKJoint or a THREE.Bone.');
        return this;
      }
    }

    joints ??= [];
    joints!.add(joint);

    if (joints!.length == 1) {
      // If this is the first joint, set as base.
      base = joints![0];
      origin = Vector3().copy(base!.getWorldPosition());
    } else {
      // Otherwise, calculate the distance for the previous joint,
      // and update the total length.
      final previousJoint = joints![joints!.length - 2];
      previousJoint.updateMatrixWorld();
      previousJoint.updateWorldPosition();
      joint.updateWorldPosition();

      final distance = previousJoint.getWorldDistance(joint);
      if (distance == 0) {
        print('bone with 0 distance between adjacent bone found');
        return this;
      }
      joint.setDistance(distance);

      joint.updateWorldPosition();
      final direction = previousJoint.getWorldDirection(joint);
      previousJoint.setOriginalDirection(direction);
      joint.setOriginalDirection(direction);

      totalLengths += distance;
    }

    if (targetObj != null) {
      effector = joint;
      effectorIndex = joint;
      target = targetObj;
    }

    return this;
  }

  /// Returns a boolean indicating whether or not this chain has an end effector.
  ///
  /// @private
  /// @return {boolean}
  _hasEffector() {
    return effector != null;
  }

  /// Returns the distance from the end effector to the target. Returns -1 if
  /// this chain does not have an end effector.
  ///
  /// @private
  /// @return {number}
  _getDistanceFromTarget() {
    return _hasEffector() ? effector!.getWorldDistance(target) : -1;
  }

  /// Connects another IKChain to this chain. The additional chain's root
  /// joint must be a member of this chain.
  ///
  /// @param {IKChain} chain
  connect(IKChain chain) {
    if (chain.base is! IKJoint) {
      print('Connecting chain does not have a base joint.');
      return;
    }

    final index = joints!.indexOf(chain.base!);

    // If we're connecting to the last joint in the chain, ensure we don't
    // already have an effector.
    if (target != null && index == joints!.length - 1) {
      print('Cannot append a chain to an end joint in a chain with a target.');
      return;
    }

    if (index == -1) {
      print(
          'Cannot connect chain that does not have a base joint in parent chain.');
      return;
    }

    joints![index].setIsSubBase();

    if (!chains.containsKey(index)) {
      chains[index] = [];
    }
    chains[index].add(chain);

    return this;
  }

  /// Update joint world positions for this chain.
  ///
  /// @private
  updateJointWorldPositions() {
    for (final joint in joints!) {
      joint.updateWorldPosition();
    }
  }

  /// Runs the forward pass of the FABRIK algorithm.
  ///
  /// @private
  forward() {
    // Copy the origin so the forward step can use before `backward()`
    // modifies it.
    origin!.copy(base!.getWorldPosition());

    // Set the effector's position to the target's position.

    if (target != null) {
      _targetPosition.setFromMatrixPosition(target.matrixWorld);
      effector!.setWorldPosition(_targetPosition);
    } else if (!joints![joints!.length - 1].isSubBase) {
      // If this chain doesn't have additional chains or a target,
      // not much to do here.
      return;
    }

    // Apply sub base positions for all joints except the base,
    // as we want to possibly write to the base's sub base positions,
    // not read from it.
    for (int i = 1; i < joints!.length; i++) {
      final joint = joints![i];
      if (joint.isSubBase) {
        joint.applySubBasePositions();
      }
    }

    for (int i = joints!.length - 1; i > 0; i--) {
      final joint = joints![i];
      final prevJoint = joints![i - 1];
      final direction = prevJoint.getWorldDirection(joint);
      final worldPosition = direction
          .multiplyScalar(joint.distance)
          .add(joint.getWorldPosition());

      // If this chain's base is a sub base, set its position in
      // `_subBaseValues` so that the forward step of the parent chain
      // can calculate the centroid and clear the values.
      // @TODO Could this have an issue if a subchain `x`'s base
      // also had its own subchain `y`, rather than subchain `x`'s
      // parent also being subchain `y`'s parent?
      if (prevJoint == base && base!.isSubBase) {
        base!.addSubBasePosition(worldPosition);
      } else {
        prevJoint.setWorldPosition(worldPosition);
      }
    }
  }

  /// Runs the backward pass of the FABRIK algorithm.
  ///
  /// @private
  backward() {
    // If base joint is a sub base, don't reset it's position back
    // to the origin, but leave it where the parent chain left it.
    if (!base!.isSubBase) {
      base!.setWorldPosition(origin);
    }

    for (int i = 0; i < joints!.length - 1; i++) {
      final joint = joints![i];
      final nextJoint = joints![i + 1];
      final jointWorldPosition = joint.getWorldPosition();

      final direction = nextJoint.getWorldDirection(joint);
      joint.setDirection(direction);

      joint.applyConstraints();

      direction.copy(joint.direction);

      // Now apply the world position to the three.js matrices. We need
      // to do this before the next joint iterates so it can generate rotations
      // in local space from its parent's matrixWorld.
      // If this is a chain sub base, let the parent chain apply the world position
      if (!(base == joint && joint.isSubBase)) {
        joint.applyWorldPosition();
      }

      nextJoint.setWorldPosition(
          direction.multiplyScalar(nextJoint.distance).add(jointWorldPosition));

      // Since we don't iterate over the last joint, handle the applying of
      // the world position. If it's also a non-effector, then we must orient
      // it to its parent rotation since otherwise it has nowhere to point to.
      if (i == joints!.length - 2) {
        if (nextJoint != effector) {
          nextJoint.setDirection(direction);
        }
        nextJoint.applyWorldPosition();
      }
    }

    return _getDistanceFromTarget();
  }
}
