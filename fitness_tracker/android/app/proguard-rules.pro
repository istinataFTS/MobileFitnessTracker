# Flutter ProGuard Rules
# These rules are applied during release builds to optimize and obfuscate code

# ========== FLUTTER CORE ==========

# Keep Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# Keep generated plugin registrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# ========== DART/FLUTTER SPECIFIC ==========

# Keep Dart native methods
-keepclassmembers class * {
    @io.flutter.embedding.engine.FlutterEngine <fields>;
}

# Keep platform channel methods
-keepclassmembers class * {
    @io.flutter.plugin.common.MethodChannel <methods>;
}

# ========== SQLITE/DATABASE ==========

# Keep SQLite database classes
-keep class androidx.sqlite.** { *; }
-keep class android.database.** { *; }
-dontwarn androidx.sqlite.**

# Keep database cursor classes
-keepclassmembers class * extends android.database.sqlite.SQLiteOpenHelper {
    <init>(...);
}

# ========== JSON SERIALIZATION ==========

# Keep JSON serialization (if using)
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exception

# Keep Gson classes (if using)
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# ========== KOTLIN ==========

# Keep Kotlin metadata
-keepattributes RuntimeVisibleAnnotations
-keep class kotlin.Metadata { *; }

# Keep Kotlin coroutines (if using)
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.coroutines.** {
    volatile <fields>;
}

# ========== ANDROID COMPONENTS ==========

# Keep Activity classes
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Keep custom views
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# ========== ENUMS ==========

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ========== PARCELABLE ==========

# Keep Parcelable implementation
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# ========== SERIALIZABLE ==========

# Keep Serializable classes
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ========== NATIVE METHODS ==========

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# ========== REFLECTION ==========

# Keep classes accessed via reflection
-keepattributes InnerClasses
-keep class **.R
-keep class **.R$* {
    <fields>;
}

# ========== OPTIMIZATION ==========

# Optimization options
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# Keep line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# ========== WARNINGS ==========

# Suppress warnings for missing classes (third-party libraries)
-dontwarn javax.annotation.**
-dontwarn javax.inject.**
-dontwarn sun.misc.**

# ========== CUSTOM APP CLASSES ==========

# If you have specific classes that must not be obfuscated, add them here
# Example:
# -keep class com.yourpackage.yourclass { *; }

# Keep data models (if they're accessed via reflection)
# -keep class com.fitnessapp.tracker.data.models.** { *; }

# ========== DEBUGGING ==========

# Print mapping to see what was removed (for troubleshooting)
-printmapping mapping.txt
-printseeds seeds.txt
-printusage usage.txt