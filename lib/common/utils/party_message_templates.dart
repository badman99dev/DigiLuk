import 'package:digiluk/models/party_model.dart';

class PartyMessageTemplate {
  final String id;
  final String displayName;
  final String template;

  const PartyMessageTemplate({
    required this.id,
    required this.displayName,
    required this.template,
  });
}

class PartyMessageTemplates {
  static List<PartyMessageTemplate> templatesFor(PartyModel party) {
    final category = party.resolvedCategory;
    final lowerName = category.displayName.toLowerCase();

    return [
      PartyMessageTemplate(
        id: 'balance_due',
        displayName: 'Balance Reminder',
        template: 'Dear {name}, as per my records on {date}, your '
            '${category.balanceDueLabel.toLowerCase()} is \u{20B9}{amount}. '
            'Please clear it at the earliest. - {business_name}',
      ),
      PartyMessageTemplate(
        id: 'payment_request',
        displayName: 'Payment Request',
        template: 'Dear {name}, please pay \u{20B9}{amount} for your '
            '${lowerName == 'custom' ? 'account' : lowerName} dues. '
            '- {business_name}',
      ),
      PartyMessageTemplate(
        id: 'friendly_reminder',
        displayName: 'Friendly Reminder',
        template: 'Hi {name}, this is a friendly reminder that '
            '\u{20B9}{amount} is pending. Please let me know when you can clear it. '
            '- {business_name}',
      ),
      PartyMessageTemplate(
        id: 'final_notice',
        displayName: 'Final Notice',
        template: 'Dear {name}, your ${category.balanceDueLabel.toLowerCase()} '
            'of \u{20B9}{amount} is still pending as of {date}. '
            'Kindly clear it immediately to avoid inconvenience. - {business_name}',
      ),
      PartyMessageTemplate(
        id: 'thanks',
        displayName: 'Thank You',
        template: 'Dear {name}, thank you for your payment. '
            'Your ${category.balanceDueLabel.toLowerCase()} is now \u{20B9}{amount}. '
            '- {business_name}',
      ),
    ];
  }

  static String fillTemplate(String template, {
    required String name,
    required String amount,
    required String businessName,
    required String date,
  }) {
    return template
        .replaceAll('{name}', name)
        .replaceAll('{amount}', amount)
        .replaceAll('{business_name}', businessName)
        .replaceAll('{date}', date);
  }
}
