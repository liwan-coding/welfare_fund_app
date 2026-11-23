# Flutter engine and plugins ship their own consumer rules; keep only what
# reflection-based libraries here need.
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
