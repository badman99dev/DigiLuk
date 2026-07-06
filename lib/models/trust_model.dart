enum TrustType { general, committee, ngo, kitty }

enum MemberRole { creator, manager, member }

class TrustModel {
  final String trustId;
  final String name;
  final String description;
  final TrustType type;
  final String createdBy;
  final String createdByUid;
  final DateTime createdAt;
  final List<TrustMember> members;
  final TrustSettings settings;
  final double totalBalance;

  TrustModel({
    required this.trustId,
    required this.name,
    required this.description,
    required this.type,
    required this.createdBy,
    required this.createdByUid,
    required this.createdAt,
    required this.members,
    required this.settings,
    this.totalBalance = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'trustId': trustId,
      'name': name,
      'description': description,
      'type': type.name,
      'createdBy': createdBy,
      'createdByUid': createdByUid,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'members': members.map((m) => m.toMap()).toList(),
      'settings': settings.toMap(),
      'totalBalance': totalBalance,
    };
  }

  factory TrustModel.fromMap(Map<String, dynamic> map) {
    return TrustModel(
      trustId: map['trustId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: TrustType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TrustType.general,
      ),
      createdBy: map['createdBy'] ?? '',
      createdByUid: map['createdByUid'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      members: (map['members'] as List<dynamic>?)
              ?.map((m) => TrustMember.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      settings: TrustSettings.fromMap(
        map['settings'] as Map<String, dynamic>? ?? {},
      ),
      totalBalance: (map['totalBalance'] ?? 0).toDouble(),
    );
  }

  bool isManager(String uid) {
    return members.any(
      (m) => m.uid == uid &&
          (m.role == MemberRole.creator || m.role == MemberRole.manager),
    );
  }

  bool isCreator(String uid) {
    return members.any((m) => m.uid == uid && m.role == MemberRole.creator);
  }

  MemberRole? getRole(String uid) {
    try {
      return members.firstWhere((m) => m.uid == uid).role;
    } catch (e) {
      return null;
    }
  }
}

class TrustMember {
  final String uid;
  final String name;
  final String email;
  final String phoneNumber;
  final String profilePic;
  final MemberRole role;
  final DateTime joinedAt;

  TrustMember({
    required this.uid,
    required this.name,
    this.email = '',
    this.phoneNumber = '',
    required this.profilePic,
    required this.role,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePic': profilePic,
      'role': role.name,
      'joinedAt': joinedAt.millisecondsSinceEpoch,
    };
  }

  factory TrustMember.fromMap(Map<String, dynamic> map) {
    return TrustMember(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profilePic: map['profilePic'] ?? '',
      role: MemberRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => MemberRole.member,
      ),
      joinedAt: DateTime.fromMillisecondsSinceEpoch(
        map['joinedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

class TrustSettings {
  final String visibility;
  final bool requireApproval;
  final int? autoDeleteDays;
  final bool allowProofRequired;
  final List<String> customCategories;

  TrustSettings({
    this.visibility = 'all_members',
    this.requireApproval = false,
    this.autoDeleteDays,
    this.allowProofRequired = false,
    this.customCategories = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'visibility': visibility,
      'requireApproval': requireApproval,
      'autoDeleteDays': autoDeleteDays,
      'allowProofRequired': allowProofRequired,
      'customCategories': customCategories,
    };
  }

  factory TrustSettings.fromMap(Map<String, dynamic> map) {
    return TrustSettings(
      visibility: map['visibility'] ?? 'all_members',
      requireApproval: map['requireApproval'] ?? false,
      autoDeleteDays: map['autoDeleteDays'],
      allowProofRequired: map['allowProofRequired'] ?? false,
      customCategories: List<String>.from(map['customCategories'] ?? []),
    );
  }
}
