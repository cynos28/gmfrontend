import 'package:flutter/material.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:permission_handler/permission_handler.dart';

/// Permission item data model
class PermissionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Permission permission;

  PermissionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.permission,
  });
}

/// Permissions screen widget
class PermissionsScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const PermissionsScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final List<PermissionItem> _permissions = [
    PermissionItem(
      title: 'Camera',
      subtitle: 'For AR overlays',
      icon: Icons.camera_alt_outlined,
      permission: Permission.camera,
    ),
    PermissionItem(
      title: 'Microphone',
      subtitle: 'For voice commands',
      icon: Icons.mic_outlined,
      permission: Permission.microphone,
    ),
    PermissionItem(
      title: 'Storage',
      subtitle: 'For offline packs',
      icon: Icons.folder_outlined,
      permission: Permission.storage,
    ),
  ];

  final Map<Permission, bool> _permissionStatus = {};

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    for (var permissionItem in _permissions) {
      final status = await permissionItem.permission.status;
      setState(() {
        _permissionStatus[permissionItem.permission] = status.isGranted;
      });
    }
  }

  Future<void> _togglePermission(PermissionItem permissionItem) async {
    final status = await permissionItem.permission.request();
    setState(() {
      _permissionStatus[permissionItem.permission] = status.isGranted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Light gray background
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 64),

                    // Title
                    Text(
                      'We need a few\npermissions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Color(AppColors.textBlack),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Subtitle
                    Text(
                      'To give you the best learning experience',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(AppColors.subText2),
                      ),
                    ),
                    const SizedBox(height: 94),

                    // Permission items
                    ...List.generate(
                      _permissions.length,
                      (index) {
                        final item = _permissions[index];
                        final isGranted =
                            _permissionStatus[item.permission] ?? false;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEEF3), // Light purple-gray
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  item.icon,
                                  size: 24,
                                  color: Color(AppColors.textBlack),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Texts
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(AppColors.textBlack),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.subtitle,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Color(AppColors.subText2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Toggle
                              Switch(
                                value: isGranted,
                                onChanged: (value) {
                                  _togglePermission(item);
                                },
                                activeColor: Color(AppColors.primaryColor),
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: const Color(0xFFD1D1D6),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Next button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 40,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(AppColors.textBlack),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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
