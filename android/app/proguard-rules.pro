# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# Drift
-keep class drift.** { *; }
-keep class * extends drift.GeneratedDatabase { *; }

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# PDF
-keep class com.itextpdf.** { *; }

# Biometric
-keep class androidx.biometric.** { *; }

# App
-keep class com.warraich.petroleum.** { *; }

# Gson
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
