import 'package:flutter/material.dart';


class SettingsPage extends StatefulWidget {
  final bool renderCameras;
  final Function(bool) onUpdateRenderCameras;

  const SettingsPage({super.key, required this.renderCameras, required this.onUpdateRenderCameras});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  late bool _localRenderCameras;

  @override
  void initState() {
    super.initState();
    _localRenderCameras = widget.renderCameras;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListTile(
        title: Text('Render Cameras'),
        trailing: Switch(
          value: _localRenderCameras,
          onChanged: (value) {
            setState(() {
              _localRenderCameras = value;
            });
            widget.onUpdateRenderCameras(value);
          },
        ),
      ),
    );
  }
}
