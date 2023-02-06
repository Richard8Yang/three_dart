import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three3d/animation/keyframe_track.dart';

import 'package:three_dart/three_dart.dart' as three;
import 'package:three_dart_jsm/three_dart_jsm.dart' as three_jsm;

class WebGlIK extends StatefulWidget {
  final String fileName;
  const WebGlIK({Key? key, required this.fileName}) : super(key: key);

  @override
  State<WebGlIK> createState() => _MyAppState();
}

class _MyAppState extends State<WebGlIK> {
  late FlutterGlPlugin three3dRender;
  three.WebGLRenderer? renderer;

  int? fboId;
  late double width;
  late double height;

  Size? screenSize;

  late three.Scene scene;
  late three.Camera camera;
  late three.Mesh mesh;

  double dpr = 1.0;

  var amount = 4;

  bool verbose = true;
  bool disposed = false;

  late three.WebGLRenderTarget renderTarget;

  dynamic sourceTexture;

  final GlobalKey<three_jsm.DomLikeListenableState> _globalKey =
      GlobalKey<three_jsm.DomLikeListenableState>();

  late three_jsm.OrbitControls controls;

  @override
  void initState() {
    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = screenSize!.height - 60;

    three3dRender = FlutterGlPlugin();

    Map<String, dynamic> options = {
      "antialias": true,
      "alpha": false,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": dpr
    };

    await three3dRender.initialize(options: options);

    setState(() {});

    // Wait for web
    Future.delayed(const Duration(milliseconds: 100), () async {
      await three3dRender.prepareContext();

      initScene();
    });
  }

  initSize(BuildContext context) {
    if (screenSize != null) {
      return;
    }

    final mqd = MediaQuery.of(context);

    screenSize = mqd.size;
    dpr = mqd.devicePixelRatio;

    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: Builder(
        builder: (BuildContext context) {
          initSize(context);
          return SingleChildScrollView(child: _build(context));
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Text("render"),
        onPressed: () {
          render();
        },
      ),
    );
  }

  Widget _build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            three_jsm.DomLikeListenable(
                key: _globalKey,
                builder: (BuildContext context) {
                  return Container(
                      width: width,
                      height: height,
                      color: Colors.black,
                      child: Builder(builder: (BuildContext context) {
                        if (kIsWeb) {
                          return three3dRender.isInitialized
                              ? HtmlElementView(
                                  viewType: three3dRender.textureId!.toString())
                              : Container();
                        } else {
                          return three3dRender.isInitialized
                              ? Texture(textureId: three3dRender.textureId!)
                              : Container();
                        }
                      }));
                }),
          ],
        ),
      ],
    );
  }

  render() {
    int t = DateTime.now().millisecondsSinceEpoch;
    final gl = three3dRender.gl;

    renderer!.render(scene, camera);

    int t1 = DateTime.now().millisecondsSinceEpoch;

    if (verbose) {
      print("render cost: ${t1 - t} ");
      print(renderer!.info.memory);
      print(renderer!.info.render);
    }

    // 重要 更新纹理之前一定要调用 确保gl程序执行完毕
    gl.flush();

    // var pixels = _gl.readCurrentPixels(0, 0, 10, 10);
    // print(" --------------pixels............. ");
    // print(pixels);

    if (verbose) print(" render: sourceTexture: $sourceTexture ");

    if (!kIsWeb) {
      three3dRender.updateTexture(sourceTexture);
    }
  }

  initRenderer() {
    Map<String, dynamic> options = {
      "width": width,
      "height": height,
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element
    };
    renderer = three.WebGLRenderer(options);
    renderer!.setPixelRatio(dpr);
    renderer!.setSize(width, height, false);
    renderer!.shadowMap.enabled = true;

    if (!kIsWeb) {
      var pars = three.WebGLRenderTargetOptions({
        "minFilter": three.LinearFilter,
        "magFilter": three.LinearFilter,
        "format": three.RGBAFormat
      });
      renderTarget = three.WebGLRenderTarget(
          (width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderTarget.samples = 4;
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget);
    }
  }

  initScene() {
    initRenderer();
    initPage();
  }

  initPage() async {
    scene = three.Scene();
    scene.background = three.Color(0xcccccc);
    scene.fog = three.FogExp2(0xcccccc, 0.002);

    camera = three.PerspectiveCamera(60, width / height, 0.01, 2000);
    camera.position.set(0, 0, 8);

    // controls

    controls = three_jsm.OrbitControls(camera, _globalKey);

    controls.enableDamping =
        true; // an animation loop is required when either damping or auto-rotation are enabled
    controls.dampingFactor = 0.05;

    controls.screenSpacePanning = false;

    controls.minDistance = 0.01;
    controls.maxDistance = 500;

    controls.maxPolarAngle = three.Math.pi / 2;

    scene = three.Scene();
    scene.background = three.Color(0xa0a0a0);
    scene.fog = three.Fog(0xa0a0a0, 200, 1000);

    var hemiLight = three.HemisphereLight(0xffffff, 0x444444);
    hemiLight.position.set(0, 200, 0);
    scene.add(hemiLight);

    var dirLight = three.DirectionalLight(0xffffff);
    dirLight.position.set(0, 200, 100);
    dirLight.castShadow = true;
    dirLight.shadow!.camera!.top = 180;
    dirLight.shadow!.camera!.bottom = -100;
    dirLight.shadow!.camera!.left = -120;
    dirLight.shadow!.camera!.right = 120;
    scene.add(dirLight);

    demoOfIK();

    animate();
  }

  final ik = three.IK();
  final pivot = three.Object3D();
  demoOfIK() {
    final chain = three.IKChain();
    final constraints = [three.IKBallConstraint(360)];
    final bones = [];

    // Create a target that the IK's effector will reach
    // for.
    final movingTarget = three.Mesh(three.SphereGeometry(0.1),
        three.MeshBasicMaterial({'color': 0xff0000}));
    movingTarget.position.z = 2;
    pivot.add(movingTarget);
    scene.add(pivot);

    // Create a chain of three.Bone's, each wrapped as an IKJoint
    // and added to the IKChain
    for (int i = 0; i < 10; i++) {
      final bone = three.Bone();
      bone.setProperty("name", "Bone_$i");
      bone.position.y = i == 0 ? 0 : 0.5;

      // Store the bone and connect it to previous bone
      // if it exists.
      bones.add(bone);
      if (i > 0) {
        bones[i - 1].add(bones[i]);
      }

      // The last IKJoint must be added with a `target` as an end effector.
      final target = i == 9 ? movingTarget : null;
      chain.add(three.IKJoint(bone, constraints: constraints),
          targetObj: target);
    }

    // Add the chain to the IK system
    ik.add(chain);

    // Ensure the root bone is added somewhere in the scene
    scene.add(ik.getRootBone());

    // Create a helper and add to the scene so we can visualize
    // the bones
    final helper = three.IKHelper(ik);
    scene.add(helper);
  }

  animate() {
    if (!mounted || disposed) {
      return;
    }

    // IK test
    pivot.rotation.x += 0.01;
    pivot.rotation.y += 0.01;
    pivot.rotation.z += 0.01;
    ik.solve();

    render();

    Future.delayed(const Duration(milliseconds: 40), () {
      animate();
    });
  }

  @override
  void dispose() {
    print(" dispose ............. ");

    disposed = true;
    three3dRender.dispose();

    super.dispose();
  }
}
