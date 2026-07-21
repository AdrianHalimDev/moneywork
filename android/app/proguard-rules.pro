# flutter_local_notifications menggunakan Gson untuk (de)serialisasi
# detail notifikasi terjadwal. R8/ProGuard menghapus generic signature
# sehingga TypeToken gagal -> force close di ScheduledNotificationReceiver.
# Aturan berikut menjaga signature & kelas terkait tetap utuh.

# Jaga generic signature & anotasi (dibutuhkan TypeToken Gson).
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Plugin notifikasi.
-keep class com.dexterous.** { *; }

# Gson.
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Hindari peringatan dari referensi opsional Gson.
-dontwarn com.google.gson.**
-dontwarn com.dexterous.**
