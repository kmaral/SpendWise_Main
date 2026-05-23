import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../models/group.dart';
import '../models/group_feature_permissions.dart';
import '../data/data_manager.dart';
import 'dart:math';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static UserProfile? _currentProfile;
  static String? _currentGroupId;

  static UserProfile? get currentProfile => _currentProfile;
  static String? get currentUserId => _currentProfile?.id;
  static String? get currentGroupId => _currentGroupId;
  static bool get isSignedIn => _currentProfile != null;

  // Generate unique invite code
  static String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // Create default group for new user (user becomes admin)
  static Future<Group> _createDefaultGroup(UserProfile profile) async {
    final groupId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final inviteCode = _generateInviteCode();

    final adminMember = GroupMember(
      userId: profile.id,
      email: profile.email,
      displayName: profile.displayName,
      photoUrl: profile.photoUrl,
      joinedAt: DateTime.now(),
      isAdmin: true,
    );

    final group = Group(
      id: groupId,
      name: '${profile.displayName}\'s Group',
      adminId: profile.id,
      members: [adminMember],
      createdAt: DateTime.now(),
      inviteCode: inviteCode,
      maxMembers: 10, // Can be adjusted
      featurePermissions:
          GroupFeaturePermissions.member(), // Default permissions
    );

    await DataManager.saveGroup(group);
    return group;
  }

  // Initialize and check for existing session
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('userId');
    final savedGroupId = prefs.getString('currentGroupId');

    if (savedUserId != null) {
      // Load user profile from local storage
      final profile = await DataManager.getUserProfile(savedUserId);
      if (profile != null) {
        _currentProfile = profile;
        _currentGroupId = savedGroupId ?? profile.currentGroupId;
      }
    }

    // Listen to Firebase auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user == null && _currentProfile != null) {
        // User signed out
        _currentProfile = null;
        _currentGroupId = null;
      }
    });
  }

  // Sign in with Google
  static Future<UserProfile?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        // Check if user profile exists
        var profile = await DataManager.getUserProfile(user.uid);

        if (profile == null) {
          // Create new profile
          profile = UserProfile(
            id: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'User',
            photoUrl: user.photoURL,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          await DataManager.saveUserProfile(profile);

          // Create default group and make user admin
          final defaultGroup = await _createDefaultGroup(profile);
          profile = profile.copyWith(currentGroupId: defaultGroup.id);
          await DataManager.saveUserProfile(profile);
        } else {
          // Update last login
          profile = profile.copyWith(lastLoginAt: DateTime.now());
          await DataManager.saveUserProfile(profile);
        }

        _currentProfile = profile;
        _currentGroupId = profile.currentGroupId;

        // Save to preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', profile.id);
        if (_currentGroupId != null) {
          await prefs.setString('currentGroupId', _currentGroupId!);
        }

        return profile;
      }
    } catch (e) {
      print('Error signing in with Google: $e');
    }
    return null;
  }

  // Attempt silent sign-in with Google (uses existing account if available)
  static Future<UserProfile?> signInSilently() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null) return null; // No account available silently

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        var profile = await DataManager.getUserProfile(user.uid);

        if (profile == null) {
          profile = UserProfile(
            id: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'User',
            photoUrl: user.photoURL,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          await DataManager.saveUserProfile(profile);

          final defaultGroup = await _createDefaultGroup(profile);
          profile = profile.copyWith(currentGroupId: defaultGroup.id);
          await DataManager.saveUserProfile(profile);
        } else {
          profile = profile.copyWith(lastLoginAt: DateTime.now());
          await DataManager.saveUserProfile(profile);
        }

        _currentProfile = profile;
        _currentGroupId = profile.currentGroupId;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', profile.id);
        if (_currentGroupId != null) {
          await prefs.setString('currentGroupId', _currentGroupId!);
        }

        return profile;
      }
    } catch (e) {
      print('Silent sign-in failed: $e');
    }
    return null;
  }

  // Sign out
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _currentProfile = null;
    _currentGroupId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('currentGroupId');
  }

  // Switch group
  static Future<void> switchGroup(String? groupId) async {
    _currentGroupId = groupId;

    if (_currentProfile != null) {
      _currentProfile = _currentProfile!.copyWith(currentGroupId: groupId);
      await DataManager.saveUserProfile(_currentProfile!);
    }

    final prefs = await SharedPreferences.getInstance();
    if (groupId != null) {
      await prefs.setString('currentGroupId', groupId);
    } else {
      await prefs.remove('currentGroupId');
    }
  }

  // Use local mode (no sign-in required)
  static Future<void> useLocalMode() async {
    final prefs = await SharedPreferences.getInstance();
    final localUserId = prefs.getString('localUserId');

    String userId;
    if (localUserId == null) {
      // Generate a unique local user ID
      userId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('localUserId', userId);
    } else {
      userId = localUserId;
    }

    var profile = await DataManager.getUserProfile(userId);
    if (profile == null) {
      profile = UserProfile(
        id: userId,
        email: 'local@device',
        displayName: 'Local User',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      await DataManager.saveUserProfile(profile);
    }

    _currentProfile = profile;
    _currentGroupId = profile.currentGroupId;

    await prefs.setString('userId', userId);
  }
}
