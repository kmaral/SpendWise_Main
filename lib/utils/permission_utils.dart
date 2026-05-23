import 'package:flutter/material.dart';
import '../services/group_service.dart';

/// Widget that conditionally shows its child based on group permissions
/// Useful for hiding features that users don't have access to
class PermissionGate extends StatelessWidget {
  final String permission;
  final Widget child;
  final Widget? fallback;
  final String? groupId;

  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
    this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: GroupService.canPerformAction(permission, groupId: groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final hasPermission = snapshot.data ?? false;

        if (hasPermission) {
          return child;
        } else {
          return fallback ?? const SizedBox.shrink();
        }
      },
    );
  }
}

/// Mixin to check permissions in any StatefulWidget
mixin PermissionCheckerMixin<T extends StatefulWidget> on State<T> {
  Future<bool> checkPermission(String action, {String? groupId}) async {
    return await GroupService.canPerformAction(action, groupId: groupId);
  }

  Future<bool> isAdmin() async {
    return await GroupService.isCurrentUserAdmin();
  }

  void showPermissionDenied() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You don\'t have permission to perform this action'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

/// Function to check permission and show error if denied
Future<bool> checkPermissionWithFeedback(
  BuildContext context,
  String action, {
  String? groupId,
}) async {
  final hasPermission = await GroupService.canPerformAction(
    action,
    groupId: groupId,
  );

  if (!hasPermission) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You don\'t have permission to perform this action'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  return hasPermission;
}
