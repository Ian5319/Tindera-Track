import 'package:camera/camera.dart';

class CameraService {
  CameraController? controller;

  Future<void> initialize() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw CameraException('NO_CAMERA', 'No camera is available on this device.');
    final selected = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cameras.first);
    controller = CameraController(selected, ResolutionPreset.medium, enableAudio: false);
    await controller!.initialize();
  }

  Future<XFile> takePhoto() async {
    final c = controller;
    if (c == null || !c.value.isInitialized) throw CameraException('NOT_READY', 'Camera is not ready.');
    return c.takePicture();
  }

  Future<void> dispose() async {
    await controller?.dispose();
    controller = null;
  }
}
