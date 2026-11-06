# FoodSight

Flutter food and nutrition prototype developed for the SUT-DIGITAL Hackathon.
The app uses Firebase, an on-device TensorFlow Lite model, and Google Maps.

## Local setup

1. Install Flutter and run `flutter pub get`.
2. Configure your own Firebase project. Use FlutterFire CLI (`flutterfire configure`)
   to generate `lib/firebase_options.dart`, or copy
   `lib/firebase_options.example.dart` to that path and fill in your Firebase app settings.
3. Download the Android app's `google-services.json` from Firebase Console and place
   it at `android/app/google-services.json`. The Android application ID is
   `com.example.my_first_app`.
4. Add `MAPS_API_KEY=YOUR_GOOGLE_MAPS_KEY` to `android/local.properties`, preserving
   the existing Flutter and Android SDK settings. A `MAPS_API_KEY` environment
   variable takes precedence for automated builds.
5. Run `flutter run`.

The local Firebase configuration files and Android local properties are ignored
by Git. Existing developer configuration stays in those local files.

## Admin data import

Copy `admin/firebase-config.example.js` to `admin/firebase-config.js` and enter
your own Firebase web app settings. The import page loads this file directly.
Configure Firebase access rules for the intended administrator before using the importer.

## Before publishing

- Restrict the Google Maps key to your Android package and signing certificate,
  and to the required Maps APIs.
- Review Firebase Authentication, Firestore Security Rules, and API restrictions
  in the Firebase and Google Cloud consoles.
- Firebase client configuration and Android Maps keys are delivered to clients.
  Enforce access controls through the cloud services.
- If a credential was exposed, replace or revoke it at its provider. Removing
  a file from Git does not revoke a credential or erase existing copies.
- Keep private settings out of commits. Share the example files for setup.
