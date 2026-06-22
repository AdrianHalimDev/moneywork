import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/wishlist_item.dart';

/// Layanan notifikasi lokal terjadwal (Android).
///
/// Menjadwalkan pengingat di perangkat — muncul walau aplikasi ditutup, tanpa
/// server. Di web semua method tidak melakukan apa-apa (no-op) karena fitur ini
/// ditujukan untuk mobile.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  // ID stabil agar penjadwalan ulang menimpa, bukan menumpuk.
  static const int _dailyId = 1000;
  static const int _wishlistBaseId = 2000;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'moneywork_reminders',
    'Pengingat MoneyWork',
    channelDescription: 'Pengingat catat transaksi & menabung',
    importance: Importance.high,
    priority: Priority.high,
  );

  NotificationDetails get _details =>
      const NotificationDetails(android: _androidDetails);

  /// Inisialisasi plugin & zona waktu. Aman dipanggil berkali-kali.
  Future<void> init() async {
    if (kIsWeb || _ready) return;
    tzdata.initializeTimeZones();
    // Asia/Jakarta sebagai default; cukup untuk pemakaian lokal.
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings);
    _ready = true;
  }

  /// Minta izin notifikasi (Android 13+) & alarm presisi. Mengembalikan
  /// `true` bila izin notifikasi diberikan.
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    final granted = await android.requestNotificationsPermission() ?? false;
    // Izin alarm presisi (untuk jadwal akurat di Android 12+).
    await android.requestExactAlarmsPermission();
    return granted;
  }

  /// Apakah izin notifikasi sudah diberikan.
  Future<bool> isEnabled() async {
    if (kIsWeb) return false;
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? false;
  }

  /// Jadwalkan pengingat harian "catat transaksi" pada [hour]:[minute].
  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) async {
    if (kIsWeb) return;
    await init();
    await _plugin.zonedSchedule(
      _dailyId,
      'Catat transaksi hari ini',
      'Jangan lupa catat pemasukan & pengeluaranmu di MoneyWork.',
      _nextInstanceOfTime(hour, minute),
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // ulang tiap hari
    );
  }

  Future<void> cancelDailyReminder() async {
    if (kIsWeb) return;
    await init();
    await _plugin.cancel(_dailyId);
  }

  /// Jadwalkan pengingat menabung bulanan untuk tiap wishlist yang punya
  /// [WishlistItem.reminderDay] aktif. Menjadwalkan ulang dari awal tiap
  /// dipanggil agar selalu sinkron dengan data terbaru.
  Future<void> scheduleWishlistReminders(List<WishlistItem> wishlist) async {
    if (kIsWeb) return;
    await init();
    // Bersihkan jadwal wishlist lama (rentang id khusus).
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id >= _wishlistBaseId && p.id < _wishlistBaseId + 1000) {
        await _plugin.cancel(p.id);
      }
    }

    final targets = wishlist
        .where((w) =>
            !w.purchased && w.reminderDay >= 1 && w.reminderDay <= 28)
        .toList();
    for (var i = 0; i < targets.length; i++) {
      final w = targets[i];
      final amount = w.monthlySaving > 0
          ? 'Sisihkan ${_short(w.monthlySaving)} untuk ${w.name}.'
          : 'Saatnya menabung untuk ${w.name}.';
      await _plugin.zonedSchedule(
        _wishlistBaseId + i,
        'Waktunya menabung 💰',
        amount,
        _nextInstanceOfDay(w.reminderDay, 9, 0),
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents:
            DateTimeComponents.dayOfMonthAndTime, // ulang tiap bulan
      );
    }
  }

  /// Batalkan semua notifikasi terjadwal.
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await init();
    await _plugin.cancelAll();
  }

  // --- Helper waktu ---

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfDay(int day, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, day, hour, minute);
    if (scheduled.isBefore(now)) {
      // Pindah ke bulan berikutnya.
      scheduled =
          tz.TZDateTime(tz.local, now.year, now.month + 1, day, hour, minute);
    }
    return scheduled;
  }

  static String _short(double v) =>
      'Rp ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}';
}
