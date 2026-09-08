# Flutter Engine & Embedding
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# Pigeon Platform Channels (ImagePicker, etc.)
-keep class dev.flutter.pigeon.** { *; }
-keep class * implements dev.flutter.pigeon.** { *; }
-keep interface dev.flutter.pigeon.** { *; }
-keepclassmembers class dev.flutter.pigeon.** { *; }

# Image Picker Android
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class * implements io.flutter.plugins.imagepicker.** { *; }
-keep class dev.flutter.pigeon.image_picker_android.** { *; }
-keep class dev.flutter.pigeon.image_picker_android.ImagePickerApi { *; }
-keep class dev.flutter.pigeon.image_picker_android.ImagePickerApi$* { *; }
-keepclassmembers class dev.flutter.pigeon.image_picker_android.** { *; }

# FFmpeg Kit
-keep class com.antonkarpenko.ffmpegkit.** { *; }
-keep class com.arthenica.ffmpegkit.** { *; }
-keep class * implements com.arthenica.ffmpegkit.** { *; }
-dontwarn com.arthenica.ffmpegkit.**
-dontwarn com.antonkarpenko.ffmpegkit.**

# Gal & Share Plus & Video Player & FlutterToast
-keep class studio.midoridesign.gal.** { *; }
-keep class dev.fluttercommunity.plus.share.** { *; }
-keep class io.flutter.plugins.videoplayer.** { *; }
-keep class io.github.ponnamkarthik.toast.fluttertoast.** { *; }

# Keep native methods and classes with @Keep
-keep class * extends java.lang.annotation.Annotation { *; }
-keep @androidx.annotation.Keep class * { *; }
-keepclasseswithmembers class * {
    native <methods>;
}
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
