import 'package:flutter/material.dart';
import 'package:impetus/core/ui_constants.dart';
import 'package:permission_handler/permission_handler.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  PermissionStatus _cameraStatus = PermissionStatus.denied;
  bool _checkingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkCamera();
  }

  Future<void> _checkCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _cameraStatus = status;
      _checkingPermission = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIConstants.deepBlack,
      body: Center(
        child: _checkingPermission
            ? const CircularProgressIndicator(color: UIConstants.primaryCyan)
            : Text(
                _cameraStatus.isGranted
                    ? 'COACH - Fotocamera autorizzata (tracking in sviluppo)'
                    : 'Permesso fotocamera necessario per il modulo Coach',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
      ),
    );
  }
}
