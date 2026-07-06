import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/features/auth/repository/auth_repository.dart';
import 'package:digiluk/models/user_model.dart';

final authControllerProvider = Provider((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository: authRepository, ref: ref);
});

final userDataAuthProvider = FutureProvider((ref) {
  final authController = ref.watch(authControllerProvider);
  return authController.getUserData();
});

class AuthController {
  final AuthRepository authRepository;
  final ProviderRef ref;
  AuthController({required this.authRepository, required this.ref});

  Future<UserModel?> getUserData() async {
    UserModel? user = await authRepository.getCurrentUserData();
    return user;
  }

  Future<void> signInWithGoogle(BuildContext context) {
    return authRepository.signInWithGoogle(context);
  }

  void saveUserDataToFirebase(
      BuildContext context, String name, File? profilePic) {
    authRepository.saveUserDataToFirebase(
      name: name,
      profilePic: profilePic,
      ref: ref,
      context: context,
    );
  }

  Future<void> updateLanguagePreference(String lang) {
    return authRepository.updateLanguagePreference(lang);
  }

  Future<void> updateBiometricEnabled(bool enabled) {
    return authRepository.updateBiometricEnabled(enabled);
  }

  Future<void> updateProfileName(String name) {
    return authRepository.updateProfileName(name);
  }

  Future<void> signOut() {
    return authRepository.signOut();
  }

  Stream<UserModel> userDataById(String userId) {
    return authRepository.userData(userId);
  }
}
