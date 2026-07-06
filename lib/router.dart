import 'package:flutter/material.dart';
import 'package:digiluk/common/widgets/error.dart';
import 'package:digiluk/mobile_layout_screen.dart';
import 'package:digiluk/features/auth/screens/login_screen.dart';
import 'package:digiluk/features/auth/screens/otp_screen.dart';
import 'package:digiluk/features/auth/screens/user_information_screen.dart';
import 'package:digiluk/features/trust/screens/create_trust_screen.dart';
import 'package:digiluk/features/trust_home/screens/trust_home_screen.dart';
import 'package:digiluk/features/add_transaction/screens/add_transaction_screen.dart';
import 'package:digiluk/features/members/screens/members_screen.dart';
import 'package:digiluk/features/trust_settings/screens/trust_settings_screen.dart';
import 'package:digiluk/features/audit_log/screens/audit_log_screen.dart';
import 'package:digiluk/features/transactions/screens/transactions_screen.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case LoginScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      );
    case OTPScreen.routeName:
      final verificationId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => OTPScreen(verificationId: verificationId),
      );
    case UserInformationScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const UserInformationScreen(),
      );
    case '/mobile-layout':
      return MaterialPageRoute(
        builder: (context) => const MobileLayoutScreen(),
      );
    case CreateTrustScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const CreateTrustScreen(),
      );
    case TrustHomeScreen.routeName:
      final trustId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => TrustHomeScreen(trustId: trustId),
      );
    case AddTransactionScreen.routeName:
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          trustId: args['trustId'],
          type: args['type'],
        ),
      );
    case MembersScreen.routeName:
      final trustId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => MembersScreen(trustId: trustId),
      );
    case TrustSettingsScreen.routeName:
      final trustId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => TrustSettingsScreen(trustId: trustId),
      );
    case AuditLogScreen.routeName:
      final trustId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => AuditLogScreen(trustId: trustId),
      );
    case TransactionsScreen.routeName:
      final trustId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => TransactionsScreen(trustId: trustId),
      );
    default:
      return MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: ErrorScreen(error: 'This page doesn\'t exist'),
        ),
      );
  }
}
