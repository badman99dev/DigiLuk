import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/features/auth/controller/auth_controller.dart';

class OTPScreen extends ConsumerWidget {
  static const String routeName = '/otp';
  final String verificationId;
  const OTPScreen({super.key, required this.verificationId});

  void verifyOTP(WidgetRef ref, BuildContext context, String userOTP) {
    if (userOTP.length == 6) {
      ref.read(authControllerProvider).verifyOTP(
            context,
            verificationId,
            userOTP,
          );
    } else {
      showSnackBar(context: context, content: 'Enter 6-digit OTP');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Enter OTP',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: digilukTextColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We have sent a 6-digit code to your phone number.',
                style: TextStyle(
                  fontSize: 14,
                  color: digilukSubTextColor,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: size.width * 0.7,
                child: TextField(
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w600,
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    hintText: '------',
                    counterText: '',
                  ),
                  onChanged: (val) {
                    if (val.length == 6) {
                      verifyOTP(ref, context, val.trim());
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text(
                    'Didn\'t receive code? ',
                    style: TextStyle(color: digilukSubTextColor),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Resend',
                      style: TextStyle(
                        color: digilukPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
