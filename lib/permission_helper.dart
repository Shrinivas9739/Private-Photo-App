import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> requestPermissions() async {
    // Request camera permission
    PermissionStatus cameraStatus = await Permission.camera.request();

    PermissionStatus storageStatus;
    if (Platform.isAndroid) {
      // For Android 13 (API 33) and above
      if (await Permission.photos.request().isGranted && await Permission.videos.request().isGranted) {
        storageStatus = PermissionStatus.granted;
      } else {
        storageStatus = PermissionStatus.denied;
      }
    } else {
      // For older Android versions (12 and below) and iOS
      storageStatus = await Permission.storage.request();
    }

    if (cameraStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return cameraStatus.isGranted && storageStatus.isGranted;
  }
}