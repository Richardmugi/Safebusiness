# TensorFlow Lite GPU support
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Needed for Google ML Kit
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Prevent stripping classes used by reflection (common in ML)
-keep class com.google.android.gms.internal.mlkit_vision_face.** { *; }
-dontwarn com.google.android.gms.internal.mlkit_vision_face.**
