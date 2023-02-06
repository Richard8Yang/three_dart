import 'package:three_dart/three3d/ik/ik_chain.dart';

/// Class representing IK structure.
class IK {
  List<IKChain> chains = [];
  bool _needsRecalculated = true;
  bool isIK = true;

  List? _orderedChains;

  //int iterations = 1;
  double tolerance = 0.05;

  /// Adds an IKChain to the IK system.
  ///
  /// @param {IKChain} chain
  add(IKChain chain) => chains.add(chain);

  /// Called if there's been any changes to an IK structure.
  /// Called internally. Not sure if this should be supported externally.
  recalculate() {
    _orderedChains = [];

    for (final rootChain in chains) {
      final orderedChains = [];
      _orderedChains!.add(orderedChains);

      final chainsToSave = [rootChain];
      while (chainsToSave.isNotEmpty) {
        final chain = chainsToSave.removeAt(0);
        orderedChains.add(chain);
        for (final subChains in chain.chains.values) {
          for (final subChain in subChains) {
            if (chainsToSave.contains(subChain)) {
              print('Recursive chain structure detected.');
              return;
            }
            chainsToSave.add(subChain);
          }
        }
      }
    }
  }

  /// Performs the IK solution and updates bones.
  solve() {
    // If we don't have a depth-sorted array of chains, generate it.
    // This is from the first `update()` call after creating.
    if (_orderedChains == null) {
      recalculate();
    }

    for (final subChains in _orderedChains!) {
      // Hardcode to one for now
      int iterations = 1; // this.iterations;

      while (iterations > 0) {
        for (int i = subChains.length - 1; i >= 0; i--) {
          subChains[i].updateJointWorldPositions();
        }

        // Run the chain's forward step starting with the deepest chains.
        for (int i = subChains.length - 1; i >= 0; i--) {
          subChains[i].forward();
        }

        // Run the chain's backward step starting with the root chain.
        bool withinTolerance = true;
        for (int i = 0; i < subChains.length; i++) {
          final distanceFromTarget = subChains[i].backward();
          if (distanceFromTarget > tolerance) {
            withinTolerance = false;
          }
        }

        if (withinTolerance) {
          break;
        }

        iterations--;

        // Get the root chain's base and randomize the rotation, maybe
        // we'll get a better change at reaching our goal
        // @TODO
        if (iterations > 0) {
          // subChains[subChains.length - 1]._randomizeRootRotation();
        }
      }
    }
  }

  /// Returns the root bone of this structure. Currently
  /// only returns the first root chain's bone.
  ///
  /// @return {THREE.Bone}
  getRootBone() {
    return chains[0].base!.bone;
  }
}
