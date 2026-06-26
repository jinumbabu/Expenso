# Drift/SQLite rules
-keep class com.sqlite3.** { *; }
-keep class org.sqlite.** { *; }
-keep class sqlite3.** { *; }

# Flutter-specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }

# Google ML Kit and Firebase
-keep class com.google.mlkit.** { *; }
-keep class com.google.firebase.** { *; }

# Android Biometrics
-keep class androidx.biometric.** { *; }

# Ignore warnings about optional Play Core and ML Kit Text Recognition classes
-dontwarn com.google.android.play.core.**
-dontwarn com.google.mlkit.vision.text.**
