import 'dart:convert';
import 'dart:io';

import 'package:ar_flutter_plugin_flutterflow/models/intrinsics.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ARRecording {

  // List of image objects
  List<MemoryImage> images = [];
  // List of camera poses
  List<Matrix4> cameraPoses = [];
  // List of camera intrinsics
  List<CameraIntrinsics> cameraIntrinsics = [];

  Future<bool> requestPermission() async {
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    }
    return false;
  }

  void clear() {
    images.clear();
    cameraPoses.clear();
    cameraIntrinsics.clear();
  }
  
  Future<Directory> _localDirectory(String recordingName) async {
    // final directory = await getApplicationDocumentsDirectory();
    Directory? directory;
    
    if (!await requestPermission()) {
      print("Permission denied!");
      directory = await getApplicationDocumentsDirectory();
    } else {
      print("Permission granted!");
      directory = Directory("/storage/emulated/0/ARCorder");
      if (!await directory.exists()) {
        await directory.create();
      }
    }
    return Directory('${directory.path}/$recordingName');
  }

  // Add image and pose to the recording
  void addSnapshot(MemoryImage image, Matrix4 pose, CameraIntrinsics intrinsics) {
    images.add(image);
    cameraPoses.add(pose);
    cameraIntrinsics.add(intrinsics);
  }

  Future<void> askRecordingName(BuildContext context) {
    // Show dialog to ask for a recordning name. 
    // Show a text asking for a name, a textfield to save the name and then two buttons to save or cancel the recording.
    // The name should be saved in a variable and then used to save the recording.
    TextEditingController nameController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // Do not fill all the screen, just small dialog
          title: const Text('Save AR Recording'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Please enter a name for the AR recording.',
              ),
              TextField(
                controller: nameController,
                decoration: InputDecoration(hintText: 'Recording name...'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(textStyle: Theme.of(context).textTheme.labelLarge),
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(textStyle: Theme.of(context).textTheme.labelLarge),
              child: const Text('Save'),
              onPressed: () {
                saveRecording(nameController.text);
                print('Recording saved as: ${nameController.text}');
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      }
    );
  }

  // Save the recording to a file
  Future<void> saveRecording(String recordingName) async {

    final path = await _localDirectory(recordingName);
    if (!await path.exists()) {
      await path.create();
    }

    final imagePath = Directory('${path.path}/images');
    if (!await imagePath.exists()) {
      await imagePath.create();
    }

    // Extract image from provider and save to .png file
    for (var i = 0; i < images.length; i++) {
      final file = File('${imagePath.path}/image_$i.png');
      print('Saving image to: $file');
      await file.writeAsBytes(images[i].bytes);
    }

    // Create the JSON transforms file with the following structure
    final jsonFile = File('${path.path}/transforms.json');
    print('Saving transforms to: $jsonFile');
    await jsonFile.writeAsString(jsonEncode(this));

    // Clear the recording
    images.clear();
    cameraPoses.clear();
    cameraIntrinsics.clear();
  }

  Map<String, dynamic> toJson() => {
    'fl_x': cameraIntrinsics[0].f_x,
    'fl_y': cameraIntrinsics[0].f_y,
    'cx': cameraIntrinsics[0].c_x,
    'cy': cameraIntrinsics[0].c_y,
    'w': cameraIntrinsics[0].w,
    'h': cameraIntrinsics[0].h,
    'frames': List.generate(images.length, (i) {
      return {
        'file_path': 'images/image_$i.png',
        'transform_matrix': [
          [cameraPoses[i].entry(0, 0), cameraPoses[i].entry(0, 1), cameraPoses[i].entry(0, 2), cameraPoses[i].entry(0, 3)],
          [cameraPoses[i].entry(1, 0), cameraPoses[i].entry(1, 1), cameraPoses[i].entry(1, 2), cameraPoses[i].entry(1, 3)],
          [cameraPoses[i].entry(2, 0), cameraPoses[i].entry(2, 1), cameraPoses[i].entry(2, 2), cameraPoses[i].entry(2, 3)],
          [0.0, 0.0, 0.0, 1.0]
        ]
      };
    })
  };
}