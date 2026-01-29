import 'package:flutter/material.dart';

class CameraPermissionDialog extends StatelessWidget {
  final VoidCallback onLetsGo;
  final VoidCallback onGoBack;

  const CameraPermissionDialog({
    super.key,
    required this.onLetsGo,
    required this.onGoBack,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Camera icon with background
            Container(
              width: 49,
              height: 49,
              decoration: BoxDecoration(
                color: const Color(0xFFDEF8EE),
                borderRadius: BorderRadius.circular(24.5),
              ),
              child: Center(
                child: Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.black87,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            const Text(
              'Camera Time',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Description
            const Text(
              'Let\'s use the camera to see magic 3D shapes! 🎉',
              style: TextStyle(
                fontSize: 17,
                color: Color(0xA349596E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Let's Go button
            SizedBox(
              width: double.infinity,
              height: 43,
              child: ElevatedButton(
                onPressed: onLetsGo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xCCED985F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Let\'s Go',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Go Back button
            SizedBox(
              width: double.infinity,
              height: 43,
              child: ElevatedButton(
                onPressed: onGoBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA6ADED),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
