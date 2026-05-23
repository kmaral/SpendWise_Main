/// HOW TO ADD ADMIN SETTINGS TO YOUR SETTINGS SCREEN
///
/// This file shows exactly how to integrate the Group Admin Settings
/// into your existing settings screen.
library;

import 'package:flutter/material.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';
import '../screens/group/group_admin_settings_screen.dart';

/// Add this to your existing SettingsScreen
/// Wherever you want the admin section to appear
///
Widget buildAdminSection(BuildContext context) {
  return FutureBuilder<bool>(
    future: GroupService.isCurrentUserAdmin(),
    builder: (context, snapshot) {
      // Don't show anything if not admin
      if (snapshot.data != true) {
        return const SizedBox.shrink();
      }

      // Admin section
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),

          // Section header
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Admin Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),

          // Group feature permissions
          ListTile(
            leading: const Icon(Icons.security, color: Colors.deepPurple),
            title: const Text('Group Feature Permissions'),
            subtitle: const Text('Control what members can access'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              final groupId = AuthService.currentGroupId;
              if (groupId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupAdminSettingsScreen(groupId: groupId),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No active group')),
                );
              }
            },
          ),

          // Optional: Group members management (if you have this screen)
          ListTile(
            leading: const Icon(Icons.people, color: Colors.deepPurple),
            title: const Text('Manage Members'),
            subtitle: const Text('Add or remove group members'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to member management screen if you have one
              // Navigator.push(...);
            },
          ),

          // Optional: Transfer admin
          ListTile(
            leading: const Icon(
              Icons.admin_panel_settings,
              color: Colors.deepPurple,
            ),
            title: const Text('Transfer Admin Rights'),
            subtitle: const Text('Make another member the admin'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Show dialog to transfer admin
              // _showTransferAdminDialog(context);
            },
          ),

          const Divider(),
        ],
      );
    },
  );
}

/// EXAMPLE: Complete Settings Screen Integration
///
class SettingsScreenWithAdminExample extends StatelessWidget {
  const SettingsScreenWithAdminExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // User Profile Section
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
            subtitle: Text('Edit your profile information'),
          ),

          // Notifications
          const ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            subtitle: Text('Manage notification preferences'),
          ),

          // Theme
          const ListTile(
            leading: Icon(Icons.palette),
            title: Text('Theme'),
            subtitle: Text('Change app appearance'),
          ),

          const Divider(),

          // Group Settings Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Group Settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // Current Group Info
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('My Group'),
            subtitle: FutureBuilder<String?>(
              future: _getCurrentGroupName(),
              builder: (context, snapshot) {
                return Text(snapshot.data ?? 'No active group');
              },
            ),
          ),

          // Switch Group
          const ListTile(
            leading: Icon(Icons.swap_horiz),
            title: Text('Switch Group'),
            subtitle: Text('Change active group'),
          ),

          // Join Group
          const ListTile(
            leading: Icon(Icons.group_add),
            title: Text('Join Group'),
            subtitle: Text('Enter invite code to join'),
          ),

          // ⭐⭐⭐ THIS IS WHERE YOU ADD THE ADMIN SECTION ⭐⭐⭐
          buildAdminSection(context),

          // More Settings
          const Divider(),
          const ListTile(
            leading: Icon(Icons.backup),
            title: Text('Backup & Sync'),
            subtitle: Text('Manage data backup'),
          ),

          const ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('Privacy'),
            subtitle: Text('Privacy and security settings'),
          ),

          const ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
            subtitle: Text('App information and version'),
          ),

          // Sign Out
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await AuthService.signOut();
                // Navigate to welcome screen
                // Navigator.pushReplacementNamed(context, '/welcome');
              }
            },
          ),
        ],
      ),
    );
  }

  Future<String?> _getCurrentGroupName() async {
    final groupId = AuthService.currentGroupId;
    if (groupId == null) return null;

    final group = await GroupService.getGroup(groupId);
    return group?.name;
  }
}

/// ALTERNATIVE: Simpler Integration
/// Just add this card to your settings screen
///
Widget buildAdminCard(BuildContext context) {
  return FutureBuilder<bool>(
    future: GroupService.isCurrentUserAdmin(),
    builder: (context, snapshot) {
      if (snapshot.data != true) return const SizedBox.shrink();

      return Card(
        margin: const EdgeInsets.all(16),
        color: Colors.deepPurple.shade50,
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                Icons.admin_panel_settings,
                color: Colors.deepPurple.shade700,
              ),
              title: Text(
                'Admin Controls',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade900,
                ),
              ),
              subtitle: const Text('You are the group administrator'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Feature Permissions'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                final groupId = AuthService.currentGroupId;
                if (groupId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          GroupAdminSettingsScreen(groupId: groupId),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      );
    },
  );
}

/// ALTERNATIVE: As a Bottom Sheet
///
void showAdminOptions(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Admin Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Feature Permissions'),
            subtitle: const Text('Control member access'),
            onTap: () {
              Navigator.pop(context);
              final groupId = AuthService.currentGroupId;
              if (groupId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupAdminSettingsScreen(groupId: groupId),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Manage Members'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to member management
            },
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Transfer Admin'),
            onTap: () {
              Navigator.pop(context);
              // Show transfer dialog
            },
          ),
        ],
      ),
    ),
  );
}

/// INSTRUCTIONS:
/// 
/// 1. Copy `buildAdminSection()` function to your settings screen
/// 2. Add it to your ListView where you want it to appear
/// 3. Make sure to import the required files:
///    - import '../services/group_service.dart';
///    - import '../services/auth_service.dart';
///    - import '../screens/group/group_admin_settings_screen.dart';
/// 4. Test by signing in as admin and navigating to settings
/// 
/// That's it! The admin section will automatically show/hide based on user role.
