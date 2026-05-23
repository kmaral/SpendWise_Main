import 'dart:math';
import '../models/group.dart';
import '../models/group_feature_permissions.dart';
import '../data/data_manager.dart';
import 'auth_service.dart';

class GroupService {
  // Generate unique invite code
  static String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // Create a new group
  static Future<Group?> createGroup(String groupName) async {
    final currentUser = AuthService.currentProfile;
    if (currentUser == null) return null;

    final groupId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final inviteCode = _generateInviteCode();

    final adminMember = GroupMember(
      userId: currentUser.id,
      email: currentUser.email,
      displayName: currentUser.displayName,
      photoUrl: currentUser.photoUrl,
      joinedAt: DateTime.now(),
      isAdmin: true,
    );

    final group = Group(
      id: groupId,
      name: groupName,
      adminId: currentUser.id,
      members: [adminMember],
      createdAt: DateTime.now(),
      inviteCode: inviteCode,
      maxMembers: 3,
    );

    await DataManager.saveGroup(group);

    // Update user's current group
    await AuthService.switchGroup(groupId);

    return group;
  }

  // Join group by invite code
  static Future<Group?> joinGroup(String inviteCode) async {
    final currentUser = AuthService.currentProfile;
    if (currentUser == null) return null;

    final group = await DataManager.getGroupByInviteCode(inviteCode);
    if (group == null) {
      throw Exception('Invalid invite code');
    }

    if (group.isFull) {
      throw Exception('Group is full (maximum ${group.maxMembers} members)');
    }

    if (group.hasMember(currentUser.id)) {
      throw Exception('You are already a member of this group');
    }

    final newMember = GroupMember(
      userId: currentUser.id,
      email: currentUser.email,
      displayName: currentUser.displayName,
      photoUrl: currentUser.photoUrl,
      joinedAt: DateTime.now(),
      isAdmin: false,
    );

    final updatedGroup = group.copyWith(members: [...group.members, newMember]);

    await DataManager.saveGroup(updatedGroup);

    // Switch to new group
    await AuthService.switchGroup(group.id);

    return updatedGroup;
  }

  // Transfer admin rights
  static Future<void> transferAdmin(String groupId, String newAdminId) async {
    final currentUser = AuthService.currentProfile;
    if (currentUser == null) return;

    final group = await DataManager.getGroup(groupId);
    if (group == null) return;

    if (!group.isAdmin(currentUser.id)) {
      throw Exception('Only admin can transfer admin rights');
    }

    if (!group.hasMember(newAdminId)) {
      throw Exception('User is not a member of this group');
    }

    // Update members list
    final updatedMembers = group.members.map((member) {
      if (member.userId == newAdminId) {
        return member.copyWith(isAdmin: true);
      } else if (member.userId == currentUser.id) {
        return member.copyWith(isAdmin: false);
      }
      return member;
    }).toList();

    final updatedGroup = group.copyWith(
      adminId: newAdminId,
      members: updatedMembers,
    );

    await DataManager.saveGroup(updatedGroup);
  }

  // Remove member from group
  static Future<void> removeMember(String groupId, String memberId) async {
    final currentUser = AuthService.currentProfile;
    if (currentUser == null) return;

    final group = await DataManager.getGroup(groupId);
    if (group == null) return;

    if (!group.isAdmin(currentUser.id)) {
      throw Exception('Only admin can remove members');
    }

    if (memberId == group.adminId) {
      throw Exception('Cannot remove admin. Transfer admin rights first.');
    }

    final updatedMembers = group.members
        .where((member) => member.userId != memberId)
        .toList();

    final updatedGroup = group.copyWith(members: updatedMembers);
    await DataManager.saveGroup(updatedGroup);
  }

  // Leave group
  static Future<void> leaveGroup(String groupId) async {
    final currentUser = AuthService.currentProfile;
    if (currentUser == null) return;

    final group = await DataManager.getGroup(groupId);
    if (group == null) return;

    if (group.isAdmin(currentUser.id) && group.members.length > 1) {
      throw Exception(
        'Admin must transfer admin rights before leaving the group',
      );
    }

    if (group.members.length == 1) {
      // Last member, delete the group
      await DataManager.deleteGroup(groupId);
    } else {
      final updatedMembers = group.members
          .where((member) => member.userId != currentUser.id)
          .toList();

      final updatedGroup = group.copyWith(members: updatedMembers);
      await DataManager.saveGroup(updatedGroup);
    }

    // Switch to personal (no group)
    await AuthService.switchGroup(null);
  }

  // Get all groups for current user
  static Future<List<Group>> getUserGroups() async {
    final currentUser = AuthService.currentProfile;
    if (currentUser == null) return [];

    return await DataManager.getUserGroups(currentUser.id);
  }

  // Get group details
  static Future<Group?> getGroup(String groupId) async {
    return await DataManager.getGroup(groupId);
  }

  // Update feature permissions (admin only)
  static Future<void> updateFeaturePermissions(
    String groupId,
    GroupFeaturePermissions newPermissions,
  ) async {
    final currentUser = AuthService.currentProfile;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final group = await DataManager.getGroup(groupId);
    if (group == null) {
      throw Exception('Group not found');
    }

    if (!group.isAdmin(currentUser.id)) {
      throw Exception('Only admin can update feature permissions');
    }

    final updatedGroup = group.copyWith(
      featurePermissions: newPermissions,
      updatedAt: DateTime.now(),
    );

    await DataManager.saveGroup(updatedGroup);
  }

  // Get current group's permissions for a feature
  static Future<GroupFeaturePermissions?> getCurrentGroupPermissions() async {
    final currentGroupId = AuthService.currentGroupId;
    if (currentGroupId == null) return null;

    final group = await DataManager.getGroup(currentGroupId);
    return group?.featurePermissions;
  }

  // Check if current user can perform an action
  static Future<bool> canPerformAction(String action, {String? groupId}) async {
    final currentUser = AuthService.currentProfile;
    if (currentUser == null) return false;

    final targetGroupId = groupId ?? AuthService.currentGroupId;
    if (targetGroupId == null) {
      return true; // No group = personal mode, all allowed
    }

    final group = await DataManager.getGroup(targetGroupId);
    if (group == null) return false;

    // Admin always has full access
    if (group.isAdmin(currentUser.id)) return true;

    // Check member permissions
    final permissions = group.featurePermissions;
    switch (action) {
      case 'viewTransactions':
        return permissions.canViewTransactions;
      case 'addTransactions':
        return permissions.canAddTransactions;
      case 'editTransactions':
        return permissions.canEditTransactions;
      case 'deleteTransactions':
        return permissions.canDeleteTransactions;
      case 'viewAccounts':
        return permissions.canViewAccounts;
      case 'manageAccounts':
        return permissions.canManageAccounts;
      case 'viewReports':
        return permissions.canViewReports;
      case 'exportData':
        return permissions.canExportData;
      case 'viewPaymentMethods':
        return permissions.canViewPaymentMethods;
      case 'managePaymentMethods':
        return permissions.canManagePaymentMethods;
      case 'viewLoans':
        return permissions.canViewLoans;
      case 'manageLoans':
        return permissions.canManageLoans;
      case 'viewCreditCards':
        return permissions.canViewCreditCards;
      case 'manageCreditCards':
        return permissions.canManageCreditCards;
      case 'importSMS':
        return permissions.canImportSMS;
      default:
        return false;
    }
  }

  // Check if current user is admin of current group
  static Future<bool> isCurrentUserAdmin() async {
    final currentUser = AuthService.currentProfile;
    final currentGroupId = AuthService.currentGroupId;

    if (currentUser == null || currentGroupId == null) return false;

    final group = await DataManager.getGroup(currentGroupId);
    if (group == null) return false;

    return group.isAdmin(currentUser.id);
  }
}
