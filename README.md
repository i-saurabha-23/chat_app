# Chat App

A Flutter chat application with:
- Username/password authentication (custom Firestore-based flow)
- Friends system (search, send/receive requests, accept/reject)
- Real-time chat using Firestore streams
- AES-encrypted message payloads
- Profile image upload (camera/gallery with permissions)
- Bottom navigation (Chats, Friends, Profile, Settings)

## Tech Stack

- Flutter (Dart)
- Firebase Core
- Cloud Firestore
- Firebase Messaging
- Flutter Local Notifications
- Provider

## Project Structure

- `lib/auth/` - sign-in, sign-up, splash, auth session
- `lib/chats/` - chat list and conversation
- `lib/friends/` - user search, friend requests, public profile
- `lib/profile/` - user profile view/edit
- `lib/widgets/` - reusable UI components
- `lib/constants/` - app constants and Firebase config

## Prerequisites

- Flutter SDK installed
- Android Studio / VS Code
- Android SDK + emulator or physical Android device
- Firebase project configured

## Setup

1. Install dependencies:

```bash
flutter pub get
```

2. Verify Firebase config in:

- `lib/constants/firebase_constants.dart`

3. Run the app:

```bash
flutter run
```

## Build APK

Debug APK:

```bash
flutter build apk --debug
```

Release APK:

```bash
flutter build apk --release
```

## Ready-to-Install APKs

For easy access (outside `build/`), APKs are copied to:

- `apk/chat_app-debug.apk`
- `apk/chat_app-release.apk`

Install with ADB:

```bash
adb install -r apk/chat_app-release.apk
```

## Notification Note

The app stores FCM tokens, but automatic push delivery for new chat messages requires a backend sender (for example, a Firebase Cloud Function trigger on new message documents).
