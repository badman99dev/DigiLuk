import 'package:flutter/material.dart';
import 'package:digiluk/common/widgets/error.dart';
import 'package:digiluk/mobile_layout_screen.dart';
import 'package:digiluk/features/auth/screens/login_screen.dart';
import 'package:digiluk/features/auth/screens/user_information_screen.dart';
import 'package:digiluk/features/trust/screens/create_trust_screen.dart';
import 'package:digiluk/features/trust_home/screens/trust_home_screen.dart';
import 'package:digiluk/features/add_transaction/screens/add_transaction_screen.dart';
import 'package:digiluk/features/members/screens/members_screen.dart';
import 'package:digiluk/features/trust_settings/screens/trust_settings_screen.dart';
import 'package:digiluk/features/audit_log/screens/audit_log_screen.dart';
import 'package:digiluk/features/transactions/screens/transactions_screen.dart';
import 'package:digiluk/features/customers/screens/customers_list_screen.dart';
import 'package:digiluk/features/customers/screens/customer_detail_screen.dart';
import 'package:digiluk/features/customers/screens/add_customer_screen.dart';
import 'package:digiluk/features/dashboard/screens/groups_list_screen.dart';
import 'package:digiluk/features/parties/screens/add_party_screen.dart';
import 'package:digiluk/features/parties/screens/edit_party_screen.dart';
import 'package:digiluk/features/parties/screens/party_detail_screen.dart';
import 'package:digiluk/features/parties/screens/party_audit_log_screen.dart';
import 'package:digiluk/features/reminders/screens/share_balance_screen.dart';
import 'package:digiluk/features/upi/screens/upi_screen.dart';
import 'package:digiluk/features/billing/screens/create_invoice_screen.dart';
import 'package:digiluk/features/stock/screens/stock_screen.dart';
import 'package:digiluk/features/reminders/screens/share_balance_screen.dart';
import 'package:digiluk/features/trust/screens/public_group_preview_screen.dart';
import 'package:digiluk/models/party_model.dart';
import 'package:digiluk/models/transaction_model.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case LoginScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const LoginScreen(),
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
          type: args['type'] as TransactionType,
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
    case CustomersListScreen.routeName:
      final trustId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => CustomersListScreen(trustId: trustId),
      );
    case CustomerDetailScreen.routeName:
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(
          trustId: args['trustId'],
          customerId: args['customerId'],
          customerName: args['customerName'],
        ),
      );
    case AddCustomerScreen.routeName:
      final trustId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => AddCustomerScreen(trustId: trustId),
      );
    case GroupsListScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const GroupsListScreen(),
      );
    case AddPartyScreen.routeName:
      final type = settings.arguments as PartyType?;
      return MaterialPageRoute(
        builder: (context) => AddPartyScreen(initialType: type ?? PartyType.customer),
      );
    case PartyDetailScreen.routeName:
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => PartyDetailScreen(
          partyId: args['partyId'] as String,
          partyName: args['partyName'] as String,
        ),
      );
    case EditPartyScreen.routeName:
      final party = settings.arguments as PartyModel;
      return MaterialPageRoute(
        builder: (context) => EditPartyScreen(party: party),
      );
    case PartyAuditLogScreen.routeName:
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => PartyAuditLogScreen(
          partyId: args['partyId'] as String,
          partyName: args['partyName'] as String,
        ),
      );
    case ShareBalanceScreen.routeName:
      final partyId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => ShareBalanceScreen(partyId: partyId),
      );
    case UPIScreen.routeName:
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => UPIScreen(partyId: args['partyId'] as String),
      );
    case CreateInvoiceScreen.routeName:
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => CreateInvoiceScreen(
          partyId: args['partyId'] as String,
          partyName: args['partyName'] as String,
        ),
      );
    case StockScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const StockScreen(),
      );
    case InvoiceListScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const InvoiceListScreen(),
      );
    case BulkRemindersScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const BulkRemindersScreen(),
      );
    case PublicGroupPreviewScreen.routeName:
      final trustId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => PublicGroupPreviewScreen(trustId: trustId),
      );
    default:
      return MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: ErrorScreen(error: 'This page doesn\'t exist'),
        ),
      );
  }
}
