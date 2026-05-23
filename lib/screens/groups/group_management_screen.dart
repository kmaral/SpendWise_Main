import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/group_service.dart';
import '../../services/auth_service.dart';
import '../../models/group.dart';

class GroupManagementScreen extends StatefulWidget {
  final String groupId;

  const GroupManagementScreen({super.key, required this.groupId});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  Group? _group;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    setState(() => _isLoading = true);
    try {
      final group = await GroupService.getGroup(widget.groupId);
      if (mounted) {
        setState(() {
          _group = group;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading group: $e')));
      }
    }
  }

  Future<void> _transferAdmin(String memberId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer Admin Rights'),
        content: const Text(
          'Are you sure you want to transfer admin rights? '
          'You will no longer be able to manage members.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Transfer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await GroupService.transferAdmin(widget.groupId, memberId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin rights transferred successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadGroup();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _removeMember(String memberId, String memberName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove $memberName from this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await GroupService.removeMember(widget.groupId, memberId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$memberName removed from group'),
              backgroundColor: Colors.green,
            ),
          );
          _loadGroup();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _leaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text(
          'Are you sure you want to leave this group? '
          'You will need an invite code to rejoin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await GroupService.leaveGroup(widget.groupId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Left group successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _shareInviteCode() {
    if (_group != null) {
      Clipboard.setData(
        ClipboardData(
          text:
              'Join my family group on KharchaBook!\n\n'
              'Group: ${_group!.name}\n'
              'Invite Code: ${_group!.inviteCode}\n\n'
              'Download the app and use this code to join.',
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invite details copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService.currentUserId;
    final isAdmin = _group != null && _group!.isAdmin(currentUserId ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Management'),
        actions: [
          if (_group != null && !isAdmin)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: _leaveGroup,
              tooltip: 'Leave Group',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _group == null
          ? const Center(child: Text('Group not found'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Group Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.family_restroom,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _group!.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Created ${_formatDate(_group!.createdAt)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${_group!.members.length}/${_group!.maxMembers} Members',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Invite Code Card
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Invite Code',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.share),
                              onPressed: _shareInviteCode,
                              tooltip: 'Share Code',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _group!.inviteCode,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: _group!.inviteCode),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Code copied'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Members Section
                Text('Members', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),

                ..._group!.members.map((member) {
                  final isMemberAdmin = member.isAdmin;
                  final isCurrentUser = member.userId == currentUserId;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: member.photoUrl != null
                            ? NetworkImage(member.photoUrl!)
                            : null,
                        child: member.photoUrl == null
                            ? Text(member.displayName[0].toUpperCase())
                            : null,
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(member.displayName)),
                          if (isMemberAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
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
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member.email),
                          Text(
                            'Joined ${_formatDate(member.joinedAt)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      trailing: isAdmin && !isCurrentUser
                          ? PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: const ListTile(
                                    leading: Icon(Icons.admin_panel_settings),
                                    title: Text('Make Admin'),
                                    dense: true,
                                  ),
                                  onTap: () => Future.delayed(
                                    Duration.zero,
                                    () => _transferAdmin(member.userId),
                                  ),
                                ),
                                if (!isMemberAdmin)
                                  PopupMenuItem(
                                    child: const ListTile(
                                      leading: Icon(
                                        Icons.remove_circle,
                                        color: Colors.red,
                                      ),
                                      title: Text(
                                        'Remove',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      dense: true,
                                    ),
                                    onTap: () => Future.delayed(
                                      Duration.zero,
                                      () => _removeMember(
                                        member.userId,
                                        member.displayName,
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : null,
                    ),
                  );
                }),
              ],
            ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} weeks ago';
    } else if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()} months ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
