import 'group_feature_permissions.dart';

class Group {
  final String id;
  final String name;
  final String adminId;
  final List<GroupMember> members;
  final DateTime createdAt;
  final String inviteCode;
  final int maxMembers;
  final String? currency; // Group currency preference
  final DateTime? updatedAt;
  final String createdBy;
  final GroupFeaturePermissions
  featurePermissions; // Admin-controlled permissions

  Group({
    required this.id,
    required this.name,
    required this.adminId,
    required this.members,
    required this.createdAt,
    required this.inviteCode,
    this.maxMembers = 3,
    this.currency = 'INR',
    this.updatedAt,
    String? createdBy,
    GroupFeaturePermissions? featurePermissions,
  }) : createdBy = createdBy ?? adminId,
       featurePermissions =
           featurePermissions ?? GroupFeaturePermissions.member();

  bool get isFull => members.length >= maxMembers;

  bool isAdmin(String userId) => adminId == userId;

  bool hasMember(String userId) => members.any((m) => m.userId == userId);

  List<GroupMember> get adminMembers =>
      members.where((m) => m.isAdmin).toList();

  int get memberCount => members.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'adminId': adminId,
      'members': members.map((m) => m.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'inviteCode': inviteCode,
      'maxMembers': maxMembers,
      'currency': currency,
      'featurePermissions': featurePermissions.toMap(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] as String,
      name: map['name'] as String,
      adminId: map['adminId'] as String,
      members: (map['members'] as List<dynamic>)
          .map((m) => GroupMember.fromMap(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      inviteCode: map['inviteCode'] as String,
      maxMembers: map['maxMembers'] as int? ?? 3,
      currency: map['currency'] as String? ?? 'INR',
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      createdBy: map['createdBy'] as String?,
      featurePermissions: map['featurePermissions'] != null
          ? GroupFeaturePermissions.fromMap(
              map['featurePermissions'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Group copyWith({
    String? id,
    String? name,
    String? adminId,
    List<GroupMember>? members,
    DateTime? createdAt,
    String? inviteCode,
    int? maxMembers,
    String? currency,
    DateTime? updatedAt,
    String? createdBy,
    GroupFeaturePermissions? featurePermissions,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      adminId: adminId ?? this.adminId,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      inviteCode: inviteCode ?? this.inviteCode,
      maxMembers: maxMembers ?? this.maxMembers,
      currency: currency ?? this.currency,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      featurePermissions: featurePermissions ?? this.featurePermissions,
    );
  }
}

class GroupMember {
  final String userId;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime joinedAt;
  final bool isAdmin;

  GroupMember({
    required this.userId,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.joinedAt,
    this.isAdmin = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'joinedAt': joinedAt.toIso8601String(),
      'isAdmin': isAdmin,
    };
  }

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      userId: map['userId'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String,
      photoUrl: map['photoUrl'] as String?,
      joinedAt: DateTime.parse(map['joinedAt'] as String),
      isAdmin: map['isAdmin'] as bool? ?? false,
    );
  }

  GroupMember copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? joinedAt,
    bool? isAdmin,
  }) {
    return GroupMember(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      joinedAt: joinedAt ?? this.joinedAt,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
