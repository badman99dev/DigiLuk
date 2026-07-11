import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:digiluk/common/utils/utils.dart';

Future<String?> pickContactPhone(BuildContext context) async {
  try {
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      showSnackBar(context: context, content: 'Contacts permission denied');
      return null;
    }

    final contact = await FlutterContacts.openExternalPick();
    if (contact == null) return null;

    final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  } catch (e) {
    showSnackBar(context: context, content: 'Could not pick contact: $e');
    return null;
  }
}
