class AppUser {
  final String? uid;
  final String? name;
  final String? email;
  final String? photoUrl;
  final String? fcmToken;

  AppUser({
    required this.uid,
    this.name,
    this.email,
    this.photoUrl,
    this.fcmToken,
  });

  factory AppUser.fromFirebaseAppUser(AppUser user) {
    return AppUser(
      uid: user.uid,
      name: user.name,
      email: user.email,
      photoUrl: user.photoUrl,
      fcmToken: user.fcmToken,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
    };
  }
}
