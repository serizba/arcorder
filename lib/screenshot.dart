import 'package:arcorder/ar_recording.dart';
import 'package:arcorder/settings.dart';
import 'package:flutter/material.dart';

//AR Flutter Plugin
import 'package:ar_flutter_plugin_flutterflow/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_flutterflow/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_flutterflow/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_flutterflow/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_flutterflow/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_flutterflow/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_flutterflow/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_flutterflow/models/ar_node.dart';
import 'package:ar_flutter_plugin_flutterflow/models/ar_hittest_result.dart';

//Other custom imports
import 'package:vector_math/vector_math_64.dart' as vector_math;

class Screenshot extends StatefulWidget {
  const Screenshot({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<Screenshot> createState() => _ScreenshotState();
}

class _ScreenshotState extends State<Screenshot> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  bool _renderCameras = true;

  List<ARNode> nodes = [];

  ARRecording arRecording = ARRecording();

  @override
  void dispose() {
    super.dispose();
    arSessionManager!.dispose();
  }

  void _updateRenderCameras(bool value) {
    setState(() {
      _renderCameras = value;
      // Reinitialize ARSessionManager to show/hide cameras
      onRemoveEverything();
      arRecording.clear(); 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(

          leading: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Image(
              image: const AssetImage('assets/icon/icon_inverted.png'),
              color: Color.fromARGB(255, 3, 169, 244)
            ),
          ),
          title: const Text('ARCorder'),
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(
                      renderCameras: _renderCameras,
                      onUpdateRenderCameras: _updateRenderCameras,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Stack(children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
        ]),
        // Place floatingActionButton centered at the bottom of the screen
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,

            children: <Widget>[
              FloatingActionButton(
                heroTag: 'remove_btn',
                onPressed: onRemoveEverything,
                // Make it a circle
                shape: const CircleBorder(),
                tooltip: 'Delete',
                // foregroundColor: Colors.red.shade800.withValues(alpha: 0.5),
                foregroundColor: Colors.black.withValues(alpha: 0.5),
                backgroundColor: Colors.white38.withValues(alpha: 0.5),
                child: const Icon(
                  Icons.delete,
                  size: 32,
                ),
              ),
              FloatingActionButton.large(
                heroTag: 'screenshot_btn',
                onPressed: onTakeScreenshot,
                tooltip: 'Take Screenshot',
                shape: const CircleBorder(),
                foregroundColor: Colors.black.withValues(alpha: 0.5),
                backgroundColor: Colors.white38.withValues(alpha: 0.5),
                child: const Icon(
                  Icons.camera,
                  size: 64,
                ),
              ),
              FloatingActionButton(
                heroTag: 'save_btn',
                onPressed: () => arRecording.askRecordingName(context),
                // Make it a circle
                shape: const CircleBorder(),
                tooltip: 'Save',
                foregroundColor: Colors.black.withValues(alpha: 0.5),
                backgroundColor: Colors.white38.withValues(alpha: 0.5),
                child: const Icon(
                  Icons.save,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat
      );
  }

  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: false,
      showWorldOrigin: false,

    );
    this.arSessionManager!.onPlaneDetected = (int n) => {};
    this.arSessionManager!.onPlaneOrPointTap = (List<ARHitTestResult> hits) => {};
    this.arObjectManager!.onInitialize();    
  }

  Future<void> onRemoveEverything() async {
    for (var node in nodes) {
      arObjectManager!.removeNode(node);
    }
    nodes.clear();
    arRecording.clear();
  }

  Future<void> onTakeScreenshot() async {

    var currentImg = await arSessionManager!.snapshot() as MemoryImage?;
    var currentPose = await arSessionManager!.getCameraPose();
    var currentIntrinsics = await arSessionManager!.getCameraIntrinsics();

    arRecording.addSnapshot(currentImg!, currentPose!, currentIntrinsics!);

    // Add camera node to the scene
    if (_renderCameras) {
      var cameraNode = ARNode(
        type: NodeType.localGLTF2,
        uri: "assets/Camera_brown.gltf",
        scale: vector_math.Vector3(0.1, 0.1, 0.1),
        transformation: currentPose,
      );
      var didAddCameraNode = await arObjectManager!.addNode(cameraNode);
      if (didAddCameraNode ?? false) {
        nodes.add(cameraNode);
      } else {
        AlertDialog(
          title: Text("Error"),
          content: Text("Adding Camera to Anchor failed"),
        );
      }
    }
  }
}