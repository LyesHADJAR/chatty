class ChattyUser {
  final String uid;
  final String email;
  String username;
  String? profileImageUrl;
  bool isVerified;
  
  ChattyUser({
    required this.uid,
    required this.email,
    required this.username,
    this.profileImageUrl,
    this.isVerified = false,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'isVerified': isVerified,
    };
  }
  
  factory ChattyUser.fromMap(Map<String, dynamic> map) {
    return ChattyUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      isVerified: map['isVerified'] ?? false,
    );
  }
}