class AppUser {
  final String? uid;
  final String? name;
  final String? email;
  final String? fcmToken;
  final String? bio;
  final String? profileImageUrl;
  final int? totalPosts;
  final int? totalLikes;
  final int? followersCount;
  final int? followingCount;

  AppUser({
    this.uid,
    this.name,
    this.email,
    this.fcmToken,
    this.bio,
    this.profileImageUrl,
    this.totalLikes,
    this.totalPosts,
    this.followersCount,
    this.followingCount,
  });

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? fcmToken,
    String? bio,
    String? profileImageUrl,
    int? totalPosts,
    int? totalLikes,
    int? followersCount,
    int? followingCount,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      fcmToken: fcmToken ?? this.fcmToken,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      totalPosts: totalPosts ?? this.totalPosts,
      totalLikes: totalLikes ?? this.totalLikes,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followersCount ?? this.followingCount,
    );
  }

  factory AppUser.fromFirebaseAppUser(AppUser user) {
    return AppUser(
      uid: user.uid,
      name: user.name,
      email: user.email,
      fcmToken: user.fcmToken,
      bio: user.bio,
      profileImageUrl: user.profileImageUrl,
      totalPosts: user.totalPosts,
      totalLikes: user.totalLikes,
      followersCount: user.followersCount,
      followingCount: user.followersCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'fcmToken': fcmToken,
      'bio': bio,
      'prfoileImageUrl': profileImageUrl,
      'totalPosts': totalPosts,
      'totalLikes': totalLikes,
      'followersCount': followersCount,
      'followingCount': followingCount,
    };
  }
}
