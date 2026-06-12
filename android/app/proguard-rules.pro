-keep class com.warraich.petroleum.** { *; }
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# local_auth
-keep class io.flutter.plugins.localauth.** { *; }

# google_sign_in
-keep class com.google.android.gms.auth.** { *; }

# shared_preferences / flutter_secure_storage
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }
