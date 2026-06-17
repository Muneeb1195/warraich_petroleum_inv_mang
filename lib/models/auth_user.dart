class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  AppUser({required this.uid, this.email, this.displayName, this.photoURL});

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          displayName == other.displayName &&
          photoURL == other.photoURL;

  @override
  int get hashCode => Object.hash(uid, email, displayName, photoURL);

  @override
  String toString() =>
      'AppUser(uid: $uid, email: $email, displayName: $displayName)';
}
