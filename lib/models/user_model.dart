class UserModel {
  final String name;
  final String uid;
  final String profilePic;
  final String phoneNumber;
  final List<String> trustIds;
  final String languagePreference;
  final bool biometricEnabled;
  final DateTime createdAt;

  UserModel({
    required this.name,
    required this.uid,
    required this.profilePic,
    required this.phoneNumber,
    required this.trustIds,
    this.languagePreference = 'en',
    this.biometricEnabled = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'uid': uid,
      'profilePic': profilePic,
      'phoneNumber': phoneNumber,
      'trustIds': trustIds,
      'languagePreference': languagePreference,
      'biometricEnabled': biometricEnabled,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] ?? '',
      uid: map['uid'] ?? '',
      profilePic: map['profilePic'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      trustIds: List<String>.from(map['trustIds'] ?? []),
      languagePreference: map['languagePreference'] ?? 'en',
      biometricEnabled: map['biometricEnabled'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  UserModel copyWith({
    String? name,
    String? profilePic,
    List<String>? trustIds,
    String? languagePreference,
    bool? biometricEnabled,
  }) {
    return UserModel(
      name: name ?? this.name,
      uid: uid,
      profilePic: profilePic ?? this.profilePic,
      phoneNumber: phoneNumber,
      trustIds: trustIds ?? this.trustIds,
      languagePreference: languagePreference ?? this.languagePreference,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      createdAt: createdAt,
    );
  }
}
