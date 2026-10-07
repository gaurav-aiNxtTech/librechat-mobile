# R8 rules for the Flutter release build. Flutter's own rules are applied by the Flutter Gradle
# plugin; plugin AARs ship consumer rules. Keep this file for app-level additions only.

# Flutter embedding references Play Core split-install classes that this app never ships.
-dontwarn com.google.android.play.core.**
