import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';
import '../models/group.dart';

/// Firebase Authentication Service
/// Handles user authentication and group management with Firebase
class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Collection references
  static CollectionReference get _usersRef => _firestore.collection('users');
  static CollectionReference get _groupsRef => _firestore.collection('groups');

  // Sign in with Google
  static Future<UserProfile?> signInWithGoogle() async {
    try {
      // Trigger Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        return await _createOrUpdateUserProfile(user);
      }
    } catch (e) {
      print('Error signing in with Google: $e');
    }
    return null;
  }

  // Sign in with email/password
  static Future<UserProfile?> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        return await _createOrUpdateUserProfile(userCredential.user!);
      }
    } catch (e) {
      print('Error signing in with email: $e');
      rethrow;
    }
    return null;
  }

  // Sign up with email/password
  static Future<UserProfile?> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);

      if (userCredential.user != null) {
        return await _createOrUpdateUserProfile(userCredential.user!);
      }
    } catch (e) {
      print('Error signing up with email: $e');
      rethrow;
    }
    return null;
  }

  // Create or update user profile
  static Future<UserProfile> _createOrUpdateUserProfile(User user) async {
    final userDoc = _usersRef.doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      // Create new user profile
      final profile = UserProfile(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'User',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      await userDoc.set(profile.toMap());
      return profile;
    } else {
      // Update existing profile
      final data = docSnapshot.data() as Map<String, dynamic>;
      final profile = UserProfile.fromMap({...data, 'id': user.uid});
      final updatedProfile = profile.copyWith(lastLoginAt: DateTime.now());
      await userDoc.update({
        'lastLoginAt': updatedProfile.lastLoginAt?.toIso8601String(),
      });
      return updatedProfile;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Get user profile
  static Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (!doc.exists) return null;
      return UserProfile.fromMap({
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id,
      });
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Update user profile
  static Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _usersRef
          .doc(profile.id)
          .set(profile.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // === GROUP OPERATIONS ===

  // Create a new group
  static Future<Group?> createGroup(String groupName) async {
    try {
      final user = currentUser;
      if (user == null) {
        print('Error creating group: No user logged in');
        return null;
      }

      final profile = await getUserProfile(user.uid);
      if (profile == null) return null;

      print('Creating group for user: ${user.uid}');

      // Generate invite code
      final inviteCode = _generateInviteCode();
      final groupId = 'group_${DateTime.now().millisecondsSinceEpoch}';

      final adminMember = GroupMember(
        userId: user.uid,
        email: profile.email,
        displayName: profile.displayName,
        photoUrl: profile.photoUrl,
        joinedAt: DateTime.now(),
        isAdmin: true,
      );

      final group = Group(
        id: groupId,
        name: groupName,
        adminId: user.uid,
        members: [adminMember],
        createdAt: DateTime.now(),
        inviteCode: inviteCode,
        maxMembers: 3,
        currency: 'INR',
        createdBy: user.uid,
      );

      await _groupsRef.doc(groupId).set(group.toMap());
      print('Group created with ID: $groupId');

      // Update user's current group
      await _usersRef.doc(user.uid).update({'currentGroupId': groupId});

      print('User document updated with groupId');
      return group;
    } catch (e, stackTrace) {
      print('Error creating group: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Join a group by invite code
  static Future<Group?> joinGroup(String inviteCode) async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final profile = await getUserProfile(user.uid);
      if (profile == null) return null;

      // Find group by invite code
      final groupSnapshot = await _groupsRef
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();

      if (groupSnapshot.docs.isEmpty) {
        throw Exception('Invalid invite code');
      }

      final groupDoc = groupSnapshot.docs.first;
      final groupData = groupDoc.data() as Map<String, dynamic>;
      final group = Group.fromMap({...groupData, 'id': groupDoc.id});

      // Check if group is full
      if (group.isFull) {
        throw Exception('Group is full (maximum ${group.maxMembers} members)');
      }

      // Check if already a member
      if (group.hasMember(user.uid)) {
        throw Exception('You are already a member of this group');
      }

      // Add user to group
      final newMember = GroupMember(
        userId: user.uid,
        email: profile.email,
        displayName: profile.displayName,
        photoUrl: profile.photoUrl,
        joinedAt: DateTime.now(),
        isAdmin: false,
      );

      final updatedMembers = [...group.members, newMember];
      await _groupsRef.doc(group.id).update({
        'members': updatedMembers.map((m) => m.toMap()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update user's current group
      await _usersRef.doc(user.uid).update({'currentGroupId': group.id});

      return group.copyWith(members: updatedMembers);
    } catch (e) {
      print('Error joining group: $e');
      rethrow;
    }
  }

  // Leave group
  static Future<void> leaveGroup(String groupId) async {
    try {
      final user = currentUser;
      if (user == null) return;

      final groupDoc = await _groupsRef.doc(groupId).get();
      if (!groupDoc.exists) return;

      final group = Group.fromMap({
        ...groupDoc.data() as Map<String, dynamic>,
        'id': groupDoc.id,
      });

      // Admin cannot leave without transferring admin rights
      if (group.isAdmin(user.uid)) {
        throw Exception(
          'Admin cannot leave. Transfer admin rights first or delete the group.',
        );
      }

      // Remove user from group members
      final updatedMembers = group.members
          .where((m) => m.userId != user.uid)
          .toList();

      await _groupsRef.doc(groupId).update({
        'members': updatedMembers.map((m) => m.toMap()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Clear user's current group
      await _usersRef.doc(user.uid).update({'currentGroupId': null});
    } catch (e) {
      print('Error leaving group: $e');
      rethrow;
    }
  }

  // Remove member from group (admin only)
  static Future<void> removeMember(String groupId, String memberId) async {
    try {
      final user = currentUser;
      if (user == null) return;

      final groupDoc = await _groupsRef.doc(groupId).get();
      if (!groupDoc.exists) return;

      final group = Group.fromMap({
        ...groupDoc.data() as Map<String, dynamic>,
        'id': groupDoc.id,
      });

      // Only admin can remove members
      if (!group.isAdmin(user.uid)) {
        throw Exception('Only admin can remove members');
      }

      // Cannot remove admin
      if (memberId == group.adminId) {
        throw Exception('Cannot remove admin. Transfer admin rights first.');
      }

      // Remove member
      final updatedMembers = group.members
          .where((m) => m.userId != memberId)
          .toList();

      await _groupsRef.doc(groupId).update({
        'members': updatedMembers.map((m) => m.toMap()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Clear removed user's current group
      await _usersRef.doc(memberId).update({'currentGroupId': null});
    } catch (e) {
      print('Error removing member: $e');
      rethrow;
    }
  }

  // Transfer admin rights
  static Future<void> transferAdmin(String groupId, String newAdminId) async {
    try {
      final user = currentUser;
      if (user == null) return;

      final groupDoc = await _groupsRef.doc(groupId).get();
      if (!groupDoc.exists) return;

      final group = Group.fromMap({
        ...groupDoc.data() as Map<String, dynamic>,
        'id': groupDoc.id,
      });

      // Only current admin can transfer rights
      if (!group.isAdmin(user.uid)) {
        throw Exception('Only admin can transfer admin rights');
      }

      // Check if new admin is a member
      if (!group.hasMember(newAdminId)) {
        throw Exception('User is not a member of this group');
      }

      // Update members list
      final updatedMembers = group.members.map((member) {
        if (member.userId == newAdminId) {
          return member.copyWith(isAdmin: true);
        } else if (member.userId == user.uid) {
          return member.copyWith(isAdmin: false);
        }
        return member;
      }).toList();

      await _groupsRef.doc(groupId).update({
        'adminId': newAdminId,
        'members': updatedMembers.map((m) => m.toMap()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error transferring admin: $e');
      rethrow;
    }
  }

  // Delete group (admin only)
  static Future<void> deleteGroup(String groupId) async {
    try {
      final user = currentUser;
      if (user == null) return;

      final groupDoc = await _groupsRef.doc(groupId).get();
      if (!groupDoc.exists) return;

      final group = Group.fromMap({
        ...groupDoc.data() as Map<String, dynamic>,
        'id': groupDoc.id,
      });

      // Only admin can delete group
      if (!group.isAdmin(user.uid)) {
        throw Exception('Only admin can delete the group');
      }

      // Clear current group for all members
      for (var member in group.members) {
        await _usersRef.doc(member.userId).update({'currentGroupId': null});
      }

      // Delete group
      await _groupsRef.doc(groupId).delete();
    } catch (e) {
      print('Error deleting group: $e');
      rethrow;
    }
  }

  // Get user's groups
  static Future<List<Group>> getUserGroups(String userId) async {
    try {
      final allGroupsSnapshot = await _groupsRef.get();
      final groups = <Group>[];

      for (var doc in allGroupsSnapshot.docs) {
        try {
          final group = Group.fromMap({
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          });
          if (group.hasMember(userId)) {
            groups.add(group);
          }
        } catch (e) {
          print('Error parsing group ${doc.id}: $e');
        }
      }

      return groups;
    } catch (e) {
      print('Error fetching user groups: $e');
      return [];
    }
  }

  // Get group by ID
  static Future<Group?> getGroup(String groupId) async {
    try {
      final doc = await _groupsRef.doc(groupId).get();
      if (!doc.exists) return null;
      return Group.fromMap({
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id,
      });
    } catch (e) {
      print('Error fetching group: $e');
      return null;
    }
  }

  // Generate unique invite code
  static String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(8, (index) {
      return chars[(random + index) % chars.length];
    }).join();
  }

  // Delete account
  static Future<bool> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      // Get user's groups
      final groups = await getUserGroups(user.uid);

      // Leave all groups
      for (var group in groups) {
        if (group.isAdmin(user.uid)) {
          // If admin, delete the group
          await deleteGroup(group.id);
        } else {
          // Otherwise just leave
          await leaveGroup(group.id);
        }
      }

      // Delete user profile
      await _usersRef.doc(user.uid).delete();

      // Delete Firebase Auth account
      await user.delete();

      // Sign out
      await signOut();

      return true;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }
}
