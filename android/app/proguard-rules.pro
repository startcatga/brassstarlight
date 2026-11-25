# Flutter engine & embedding — keep and don't warn.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Google Play Core (Play Feature Delivery / deferred components).
# Flutter's Android embedding references these classes for dynamic feature
# modules, but this app uses no deferred components — the classes aren't on the
# classpath, so R8 fails with "missing class" warnings. These rules tell R8 to
# ignore them. Safe: the code paths are never exercised at runtime.
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-keep class com.google.android.play.core.** { *; }
