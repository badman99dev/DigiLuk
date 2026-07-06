# DigiLuk

Transparent Trust & Committee Fund Management App built with Flutter + Firebase.

## Features

- Phone OTP Authentication (Firebase Auth)
- Create & Manage Trusts (General, Committee, NGO, Kitty)
- Multi-Manager Support with Role-Based Access (Creator, Manager, Member)
- Income & Expense Tracking with Categories
- Bill/Receipt Photo Proof Upload
- Approval Workflow for Expenses
- Immutable Audit Log - Every Action Recorded
- Auto-Delete Timer (Configurable: 30-365 days)
- Real-time Balance Dashboard
- Analytics with Charts (Income vs Expense)
- Transaction Filtering (Type, Status)
- Member Management (Invite by Phone, Promote/Demote)
- Trust Settings (Visibility, Approval, Auto-Delete)
- Hindi + English Bilingual Support
- Biometric Lock Support
- PDF Report Generation

## Tech Stack

- **Frontend**: Flutter 3.x
- **State Management**: Riverpod 2.0
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Charts**: fl_chart

## Setup

1. Replace `android/app/google-services.json` with your Firebase project config
2. Replace `lib/firebase_options.dart` with your Firebase options (run `flutterfire configure`)
3. Run `flutter pub get`
4. Run `flutter run`

## Build APK

```bash
flutter build apk --debug
```

## License

MIT
