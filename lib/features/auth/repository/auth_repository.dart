import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:digiluk/common/repositories/cloudinary_repository.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/models/user_model.dart';
import 'package:digiluk/features/auth/screens/user_information_screen.dart';

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    googleSignIn: GoogleSignIn(),
  ),
);

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final GoogleSignIn googleSignIn;
  AuthRepository({
    required this.auth,
    required this.firestore,
    required this.googleSignIn,
  });

  Future<UserModel?> getCurrentUserData() async {
    if (auth.currentUser == null) {
      return null;
    }
    var userData =
        await firestore.collection('users').doc(auth.currentUser!.uid).get();
    UserModel? user;
    if (userData.data() != null) {
      user = UserModel.fromMap(userData.data()!);
    }
    return user;
  }

  Future<bool> signInWithGoogle(BuildContext context) async {
    try {
      debugPrint('=== Google Sign In START ===');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('User cancelled Google sign in');
        return false;
      }

      debugPrint('Google user: ${googleUser.displayName} - ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await auth.signInWithCredential(credential);
      debugPrint('Firebase auth success: ${userCredential.user?.uid}');

      bool userExists = await _checkUserExists(userCredential.user!.uid);
      debugPrint('User exists in Firestore: $userExists');

      if (!userExists) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          UserInformationScreen.routeName,
          (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/mobile-layout',
          (route) => false,
        );
      }
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuth error: ${e.code} - ${e.message}');
      showSnackBar(context: context, content: e.message ?? 'Auth failed');
      return false;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      showSnackBar(context: context, content: e.toString());
      return false;
    }
  }

  Future<bool> _checkUserExists(String uid) async {
    var doc = await firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

  void saveUserDataToFirebase({
    required String name,
    required File? profilePic,
    required ProviderRef ref,
    required BuildContext context,
  }) async {
    try {
      String uid = auth.currentUser!.uid;
      String? googlePhotoUrl = auth.currentUser!.photoURL;
      String? googleEmail = auth.currentUser!.email;
      String? googleDisplayName = auth.currentUser!.displayName;

      String photoUrl = googlePhotoUrl ??
          'https://ui-avatars.com/api/?name=${name.split(' ').join('+')}&background=1A73E8&color=fff&size=256';

      if (profilePic != null) {
        photoUrl = await ref
            .read(cloudinaryRepositoryProvider)
            .uploadImage(profilePic, folder: 'digiluk/profilePic');
      }

      var user = UserModel(
        name: name.isNotEmpty ? name : (googleDisplayName ?? 'User'),
        uid: uid,
        profilePic: photoUrl,
        phoneNumber: auth.currentUser!.phoneNumber ?? '',
        email: googleEmail ?? '',
        trustIds: [],
        createdAt: DateTime.now(),
      );

      await firestore.collection('users').doc(uid).set(user.toMap());
      debugPrint('User data saved to Firestore');

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/mobile-layout',
        (route) => false,
      );
    } catch (e) {
      debugPrint('Save user data error: $e');
      showSnackBar(context: context, content: e.toString());
    }
  }

  Future<void> updateLanguagePreference(String lang) async {
    if (auth.currentUser == null) return;
    await firestore.collection('users').doc(auth.currentUser!.uid).update({
      'languagePreference': lang,
    });
  }

  Future<void> updateBiometricEnabled(bool enabled) async {
    if (auth.currentUser == null) return;
    await firestore.collection('users').doc(auth.currentUser!.uid).update({
      'biometricEnabled': enabled,
    });
  }

  Future<void> updateProfileName(String name) async {
    if (auth.currentUser == null) return;
    await firestore.collection('users').doc(auth.currentUser!.uid).update({
      'name': name,
    });
  }

  Future<void> signOut() async {
    await auth.signOut();
    await googleSignIn.signOut();
  }

  Stream<UserModel?> userDataStream() {
    if (auth.currentUser == null) return Stream.value(null);
    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .snapshots()
        .map((event) =>
            event.exists ? UserModel.fromMap(event.data()!) : null);
  }

  Stream<UserModel> userData(String userId) {
    return firestore.collection('users').doc(userId).snapshots().map(
          (event) => UserModel.fromMap(event.data()!),
        );
  }
}
