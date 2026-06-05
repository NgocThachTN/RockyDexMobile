class ProfileModel {
  final String userId;
  final String avatarUrl;
  final String themePreference;
  final String readingLayout;
  final double readingBrightness;

  const ProfileModel({
    required this.userId,
    this.avatarUrl = '',
    this.themePreference = 'system',
    this.readingLayout = 'vertical',
    this.readingBrightness = 1.0,
  });

  ProfileModel copyWith({
    String? userId,
    String? avatarUrl,
    String? themePreference,
    String? readingLayout,
    double? readingBrightness,
  }) {
    return ProfileModel(
      userId: userId ?? this.userId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      themePreference: themePreference ?? this.themePreference,
      readingLayout: readingLayout ?? this.readingLayout,
      readingBrightness: readingBrightness ?? this.readingBrightness,
    );
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      userId: json['user_id'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      themePreference: json['theme_preference'] as String? ?? 'system',
      readingLayout: json['reading_layout'] as String? ?? 'vertical',
      readingBrightness: (json['reading_brightness'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'avatar_url': avatarUrl,
      'theme_preference': themePreference,
      'reading_layout': readingLayout,
      'reading_brightness': readingBrightness,
    };
  }
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final String createdAt;
  final ProfileModel profile;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    required this.profile,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? createdAt,
    ProfileModel? profile,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      profile: profile ?? this.profile,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      profile: json['profile'] != null
          ? ProfileModel.fromJson(json['profile'] as Map<String, dynamic>)
          : ProfileModel(userId: json['id'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'created_at': createdAt,
      'profile': profile.toJson(),
    };
  }
}
