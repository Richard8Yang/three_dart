import 'package:three_dart/three_dart.dart';

/// Mesh for representing an IKJoint.
/// @private
/// @extends {THREE.Object3d}
class BoneHelper extends Object3D {
  late Object3D boneMesh;
  late AxesHelper axesHelper;

  /// @param {number} height
  /// @param {number?} boneSize
  /// @param {number?} axesSize
  BoneHelper(double height, double boneSize, double axesSize) : super() {
    // If our bone has 0 height (like an end effector),
    // use a dummy Object3D instead, otherwise the ConeBufferGeometry
    // will fall back to its default and not use 0 height.
    if (height != 0) {
      final geo = ConeGeometry(boneSize, height, 4);
      //geo.applyMatrix4(Matrix4().makeRotationAxis(Vector3(1, 0, 0), Math.pi / 2.0));
      boneMesh = Mesh(
          geo,
          MeshBasicMaterial({
            'color': 0xff0000,
            'wireframe': true,
            'depthTest': false,
            'depthWrite': false,
          }));
    } else {
      boneMesh = Object3D();
    }

    // Offset the bone so that its rotation point is at the base of the bone
    boneMesh.position.y = height / 2;
    add(boneMesh);

    axesHelper = AxesHelper(axesSize);
    add(axesHelper);
  }
}

/// Class for visualizing an IK system.
/// @extends {THREE.Object3d}
class IKHelper extends Object3D {
  IK ik;
  late Color _color;
  late bool _showBones;
  late bool _showAxes;
  late bool _wireframe;
  late double _boneSize;
  late double _axesSize;

  final _meshes = {};

  /// Creates a visualization for an IK.
  ///
  /// @param {IK} ik
  /// @param {Object} config
  /// @param {THREE.Color} [config.color]
  /// @param {boolean} [config.showBones]
  /// @param {boolean} [config.showAxes]
  /// @param {boolean} [config.wireframe]
  /// @param {number} [config.axesSize]
  /// @param {number} [config.boneSize]
  IKHelper(this.ik,
      {Color? color,
      bool showBones = true,
      double boneSize = 0.1,
      bool showAxes = true,
      double axesSize = 0.2,
      bool wireframe = true})
      : super() {
    color = color ?? Color(0xff0077);
    _showBones = showBones;
    _showAxes = showAxes;
    _wireframe = wireframe;
    _boneSize = boneSize;
    _axesSize = axesSize;

    for (final rootChain in ik.chains) {
      final chainsToMeshify = [rootChain];
      while (chainsToMeshify.isNotEmpty) {
        final chain = chainsToMeshify.first;
        chainsToMeshify.removeAt(0);
        for (int i = 0; i < chain.joints!.length; i++) {
          final joint = chain.joints![i];
          double distance = 0;
          if (i < chain.joints!.length - 1) {
            final nextJoint = chain.joints![i + 1];
            distance = nextJoint.distance;
          }

          // If a sub base, don't make another bone
          if (chain.base == joint && chain != rootChain) {
            continue;
          }

          final mesh = BoneHelper(distance, boneSize, axesSize);
          mesh.matrixAutoUpdate = false;
          _meshes[joint] = mesh;
          add(mesh);
        }
        for (final subChains in chain.chains.values) {
          for (final subChain in subChains) {
            chainsToMeshify.add(subChain);
          }
        }
      }
    }
  }

  bool get showBones => _showBones;
  set showBones(bool showBones) {
    if (showBones == _showBones) {
      return;
    }
    _meshes.forEach((joint, mesh) {
      if (showBones) {
        mesh.add(mesh.boneMesh);
      } else {
        mesh.remove(mesh.boneMesh);
      }
    });
    _showBones = showBones;
  }

  bool get showAxes => _showAxes;
  set showAxes(bool showAxes) {
    if (showAxes == _showAxes) {
      return;
    }
    _meshes.forEach((joint, mesh) {
      if (showAxes) {
        mesh.add(mesh.axesHelper);
      } else {
        mesh.remove(mesh.axesHelper);
      }
    });
    _showAxes = showAxes;
  }

  bool get wireframe => _wireframe;
  set wireframe(bool wireframe) {
    if (wireframe == _wireframe) {
      return;
    }
    _meshes.forEach((joint, mesh) {
      if (mesh.boneMesh.material) {
        mesh.boneMesh.material.wireframe = wireframe;
      }
    });
    _wireframe = wireframe;
  }

  Color get color => _color;
  set color(color) {
    if (_color.equals(color)) {
      return;
    }
    color = (color is Color) ? color : Color(color);
    _meshes.forEach((joint, mesh) {
      if (mesh.boneMesh.material) {
        mesh.boneMesh.material.color = color;
      }
    });
    _color = color;
  }

  @override
  updateMatrixWorld([bool force = false]) {
    _meshes.forEach((joint, mesh) {
      mesh.matrix.copy(joint.bone.matrixWorld);
    });
    super.updateMatrixWorld(force);
  }
}
