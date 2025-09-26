import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Check camera permission status
  static Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Request camera permission
  static Future<PermissionStatus> requestCameraPermission() async {
    return await Permission.camera.request();
  }

  /// Check notification permission status
  static Future<bool> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Request notification permission
  static Future<PermissionStatus> requestNotificationPermission() async {
    return await Permission.notification.request();
  }

  /// Open app settings
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Check if permission is permanently denied
  static Future<bool> isPermissionPermanentlyDenied(
    Permission permission,
  ) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }

  /// Check if permission is denied
  static Future<bool> isPermissionDenied(Permission permission) async {
    final status = await permission.status;
    return status.isDenied;
  }
}
