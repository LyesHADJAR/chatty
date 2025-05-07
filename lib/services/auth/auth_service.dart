import 'package:chatty/services/storage/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatty/models/chat_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    final result =
        await _firestore
            .collection("usernames")
            .doc(username.toLowerCase())
            .get();

    return !result.exists;
  }

  // Register username in the system
  Future<void> registerUsername(String uid, String username) async {
    // Store lowercase username for case-insensitive uniqueness
    await _firestore.collection("usernames").doc(username.toLowerCase()).set({
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Sign in with email/username and password
  Future<UserCredential> signIn(String emailOrUsername, String password) async {
    try {
      // Check if input is email or username
      bool isEmail = emailOrUsername.contains('@');

      if (isEmail) {
        // Sign in with email
        return await _auth.signInWithEmailAndPassword(
          email: emailOrUsername,
          password: password,
        );
      } else {
        // Find email associated with username
        final usernameDoc =
            await _firestore
                .collection("usernames")
                .doc(emailOrUsername.toLowerCase())
                .get();

        if (!usernameDoc.exists) {
          throw Exception('No user found with this username');
        }

        final uid = usernameDoc.data()?['uid'];
        final userDoc = await _firestore.collection("Users").doc(uid).get();
        final email = userDoc.data()?['email'] ?? '';

        // Sign in with email
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        return credential;
      }
    } on FirebaseAuthException catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign up with email, password and username
  Future<UserCredential> signUp(String email, String password, String username) async {
  try {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email, 
      password: password,
    );
    
    // Generate initial avatar
    final storageService = StorageService();
    final avatarUrl = storageService.generateAvatarUrl(username, email);
    
    // Save the user to database
    _firestore.collection('Users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'email': email,
      'username': username,
      'profileImageUrl': avatarUrl,
      'createdAt': Timestamp.now(),
    });
    
    return cred;
  } on FirebaseAuthException catch (e) {
    throw Exception(e.message);
  }
}



  // Update username
  Future<void> updateUsername(String newUsername) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Check if username is available
      bool isAvailable = await isUsernameAvailable(newUsername);
      if (!isAvailable) {
        throw Exception('Username already taken');
      }

      // Get current username
      final userDoc = await _firestore.collection("Users").doc(user.uid).get();
      final currentUsername = userDoc.data()?['username'] ?? '';

      // Delete old username record
      await _firestore
          .collection("usernames")
          .doc(currentUsername.toLowerCase())
          .delete();

      // Register new username
      await registerUsername(user.uid, newUsername);

      // Update user profile
      await _firestore.collection("Users").doc(user.uid).update({
        "username": newUsername,
      });
    } catch (e) {
      throw Exception('Failed to update username: $e');
    }
  }

  // Get current user details
  Future<ChattyUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection("Users").doc(user.uid).get();
    if (!doc.exists) return null;

    return ChattyUser.fromMap(doc.data() as Map<String, dynamic>);
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Send verification email
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Check if email is verified
  bool isEmailVerified() {
    final user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  // Reload user to get latest verification status
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }
}
