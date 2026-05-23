import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/group_service.dart';
import '../../models/group.dart';
import '../groups/create_group_screen.dart';
import '../groups/join_group_screen.dart';
import '../groups/group_management_screen.dart';
import '../group/group_admin_settings_screen.dart';
import '../auth/welcome_screen.dart';

class AccountProfileScreen extends StatefulWidget {
  const AccountProfileScreen({super.key});

  @override
  State<AccountProfileScreen> createState() => _AccountProfileScreenState();
}

class _AccountProfileScreenState extends State<AccountProfileScreen>
    with SingleTickerProviderStateMixin {
  List<Group> _userGroups = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadUserGroups();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserGroups() async {
    setState(() => _isLoading = true);
    try {
      final groups = await GroupService.getUserGroups();
      if (mounted) {
        setState(() {
          _userGroups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _switchGroup(String? groupId) async {
    await AuthService.switchGroup(groupId);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            groupId == null
                ? 'Switched to personal mode'
                : 'Switched to group mode',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = AuthService.currentProfile;
    final currentGroupId = AuthService.currentGroupId;
    final isSignedIn =
        AuthService.isSignedIn &&
        profile != null &&
        !profile.id.startsWith('local_');

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: profile?.photoUrl != null
                      ? NetworkImage(profile!.photoUrl!)
                      : null,
                  child: profile?.photoUrl == null
                      ? Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  profile?.displayName ?? 'User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (profile?.email != null && profile!.email != 'local@device')
                  Text(
                    profile.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
              ],
            ),
          ),

          // Sign In Prompt (if local mode)
          if (!isSignedIn)
            Card(
              margin: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_upload,
                      size: 48,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sign in to enable family groups and sync',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed:
                          _signOut, // This will redirect to welcome screen
                      icon: const Icon(Icons.login),
                      label: const Text('Sign In with Google'),
                    ),
                  ],
                ),
              ),
            ),

          // Current Mode
          if (isSignedIn) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Current Mode',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListTile(
                leading: Icon(
                  currentGroupId != null ? Icons.group : Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  currentGroupId != null ? 'Group Mode' : 'Personal Mode',
                ),
                subtitle: Text(
                  currentGroupId != null
                      ? 'Sharing with family members'
                      : 'Only you can see your data',
                ),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
            ),
          ],

          // Groups Section
          if (isSignedIn) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Family Groups',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateGroupScreen(),
                            ),
                          );
                          if (result == true) _loadUserGroups();
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Create'),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const JoinGroupScreen(),
                            ),
                          );
                          if (result == true) _loadUserGroups();
                        },
                        icon: const Icon(Icons.group_add, size: 18),
                        label: const Text('Join'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RotationTransition(
                        turns: _rotationAnimation,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '₹',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading...',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else if (_userGroups.isEmpty)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.family_restroom,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No groups yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create or join a family group to share expenses',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._userGroups.map((group) {
                final isCurrentGroup = group.id == currentGroupId;
                final isAdmin = group.isAdmin(profile.id);

                return Card(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  elevation: isCurrentGroup ? 4 : 1,
                  child: Column(
                    children: [
                      // Main Group Info
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: isCurrentGroup
                              ? Colors.blue
                              : Colors.grey[300],
                          child: Text(
                            group.name[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isCurrentGroup
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                group.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isAdmin)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            if (isCurrentGroup)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${group.members.length} member${group.members.length != 1 ? 's' : ''}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.key,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Code: ${group.inviteCode}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 16),
                                    onPressed: () => _shareInviteCode(group),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Copy invite code',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Quick Actions
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Row(
                          children: [
                            if (!isCurrentGroup)
                              Expanded(
                                child: _buildQuickActionCard(
                                  icon: Icons.swap_horiz,
                                  label: 'Switch',
                                  color: Colors.blue,
                                  onTap: () => _switchGroup(group.id),
                                ),
                              ),
                            if (!isCurrentGroup) const SizedBox(width: 8),
                            Expanded(
                              child: _buildQuickActionCard(
                                icon: Icons.settings,
                                label: 'Manage',
                                color: Colors.orange,
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          GroupManagementScreen(
                                            groupId: group.id,
                                          ),
                                    ),
                                  );
                                  if (result == true) _loadUserGroups();
                                },
                              ),
                            ),
                            if (isAdmin) const SizedBox(width: 8),
                            if (isAdmin)
                              Expanded(
                                child: _buildQuickActionCard(
                                  icon: Icons.admin_panel_settings,
                                  label: 'Permissions',
                                  color: Colors.purple,
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            GroupAdminSettingsScreen(
                                              groupId: group.id,
                                            ),
                                      ),
                                    );
                                    if (result == true) _loadUserGroups();
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

            // Switch to Personal Button
            if (currentGroupId != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: () => _switchGroup(null),
                  icon: const Icon(Icons.person),
                  label: const Text('Switch to Personal Mode'),
                ),
              ),
          ],

          const Divider(height: 32),

          // Sign Out
          if (isSignedIn)
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareInviteCode(Group group) async {
    // Show a simple dialog with the code
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share this code with family members to join the group:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    group.inviteCode,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      // In a real app, you would use a clipboard package
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invite code copied!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    tooltip: 'Copy code',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Group: ${group.name}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'Members: ${group.members.length}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
