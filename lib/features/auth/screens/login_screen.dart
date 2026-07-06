import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/utils/utils.dart';
import 'package:digiluk/common/widgets/custom_button.dart';
import 'package:digiluk/features/auth/controller/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final phoneController = TextEditingController();
  Country? country;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  void pickCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country c) {
        setState(() => country = c);
      },
    );
  }

  void sendPhoneNumber() {
    String phoneNumber = phoneController.text.trim();
    if (country != null && phoneNumber.isNotEmpty) {
      ref
          .read(authControllerProvider)
          .signInWithPhone(context, '+${country!.phoneCode}$phoneNumber');
    } else {
      showSnackBar(context: context, content: 'Please fill all fields');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: size.height - 48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [digilukPrimary, digilukPrimaryDark],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: digilukWhite,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'DigiLuk',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: digilukTextColor,
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    'Transparent Trust Management',
                    style: TextStyle(
                      fontSize: 14,
                      color: digilukSubTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                const Text(
                  'Verify your number',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: digilukTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'DigiLuk will send an OTP to verify your phone number.',
                  style: TextStyle(
                    fontSize: 14,
                    color: digilukSubTextColor,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: pickCountry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: digilukDividerColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          country != null
                              ? '${country!.flagEmoji} ${country!.name}'
                              : 'Select Country',
                          style: TextStyle(
                            color: country != null
                                ? digilukTextColor
                                : digilukSubTextColor,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: digilukGrey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (country != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '+${country!.phoneCode}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    Expanded(
                      child: TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'Phone number',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Send OTP',
                  onPressed: sendPhoneNumber,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
