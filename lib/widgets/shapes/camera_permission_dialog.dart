import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Shows a dialog requesting camera permission.
/// Returns true if permission is granted, false otherwise.
Future<bool> showCameraPermissionDialog(BuildContext context) async {
  // First check if permission is already granted
  var status = await Permission.camera.status;
  if (status.isGranted) {
    return true;
  }

  // Show dialog explaining why we need permission
  if (context.mounted) {
    final bool? shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.blue, size: 28),
              SizedBox(width: 8),
              Text(
                'Camera Access',
                style: TextStyle(
                  fontFamily: 'Be Vietnam Pro',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: const Text(
            'This feature requires camera access to detect shapes in real-time. '
            'Please allow camera permission to continue.',
            style: TextStyle(
              fontFamily: 'Be Vietnam Pro',
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Go Back',
                style: TextStyle(
                  fontFamily: 'Be Vietnam Pro',
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Allow Camera',
                style: TextStyle(
                  fontFamily: 'Be Vietnam Pro',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldRequest == true) {
      // Request permission
      status = await Permission.camera.request();

      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        // Show dialog to open settings
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text(
                  'Permission Required',
                  style: TextStyle(
                    fontFamily: 'Be Vietnam Pro',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                content: const Text(
                  'Camera permission is required for this feature. '
                  'Please enable it in your device settings.',
                  style: TextStyle(
                    fontFamily: 'Be Vietnam Pro',
                    fontSize: 14,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Be Vietnam Pro',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      openAppSettings();
                    },
                    child: const Text(
                      'Open Settings',
                      style: TextStyle(
                        fontFamily: 'Be Vietnam Pro',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
        return false;
      }
    }
  }

  return false;
}
