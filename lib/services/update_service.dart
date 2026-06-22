import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Informasi rilis terbaru yang dipublikasikan ke Firestore.
///
/// Disimpan di dokumen `meta/app_version`:
/// ```
/// {
///   "latestVersionCode": 5,            // bandingkan dengan build number (+N)
///   "latestVersionName": "1.1.3",      // untuk ditampilkan ke pengguna
///   "apkUrl": "https://.../app.apk",   // URL unduh langsung APK
///   "releaseNotes": "Perbaikan ...",   // opsional
///   "mandatory": false                 // true = update wajib, dialog tak bisa ditutup
/// }
/// ```
@immutable
class AppRelease {
  const AppRelease({
    required this.versionCode,
    required this.versionName,
    required this.apkUrl,
    this.releaseNotes = '',
    this.mandatory = false,
  });

  final int versionCode;
  final String versionName;
  final String apkUrl;
  final String releaseNotes;
  final bool mandatory;

  static AppRelease? fromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    final code = (data['latestVersionCode'] as num?)?.toInt();
    final url = data['apkUrl'] as String?;
    if (code == null || url == null || url.isEmpty) return null;
    return AppRelease(
      versionCode: code,
      versionName: (data['latestVersionName'] as String?) ?? '',
      apkUrl: url,
      releaseNotes: (data['releaseNotes'] as String?) ?? '',
      mandatory: (data['mandatory'] as bool?) ?? false,
    );
  }
}

/// Status unduhan untuk menampilkan progres ke pengguna.
typedef DownloadProgress = void Function(double fraction);

/// Layanan update OTA self-hosted: membandingkan versi terpasang dengan
/// dokumen rilis di Firestore, mengunduh APK, lalu membuka installer Android.
///
/// Aman dipanggil di platform mana pun: di luar Android semua operasi menjadi
/// no-op karena pemasangan APK hanya relevan di Android.
class UpdateService {
  /// Hanya Android yang mendukung pemasangan APK dari aplikasi.
  bool get _supported => !kIsWeb && Platform.isAndroid;

  /// Build number aplikasi yang sedang berjalan (bagian `+N` dari versi).
  Future<int> currentVersionCode() async {
    final info = await PackageInfo.fromPlatform();
    return int.tryParse(info.buildNumber) ?? 0;
  }

  /// Periksa apakah ada rilis lebih baru. Mengembalikan [AppRelease] bila
  /// versinya lebih tinggi dari yang terpasang, atau `null` bila sudah terbaru,
  /// platform tak didukung, atau dokumen rilis tidak ada/tidak valid.
  Future<AppRelease?> checkForUpdate() async {
    if (!_supported) return null;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('meta')
          .doc('app_version')
          .get();
      final release = AppRelease.fromMap(snap.data());
      if (release == null) return null;
      final current = await currentVersionCode();
      return release.versionCode > current ? release : null;
    } catch (_) {
      // Gagal jaringan / izin: jangan ganggu pengguna, anggap tak ada update.
      return null;
    }
  }

  /// Unduh APK ke direktori sementara dan kembalikan path file-nya.
  /// Memanggil [onProgress] dengan fraksi 0..1 selama mengunduh.
  Future<String> downloadApk(
    String url, {
    DownloadProgress? onProgress,
  }) async {
    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(url));
      final res = await client.send(req);
      if (res.statusCode != 200) {
        throw Exception('Gagal mengunduh (HTTP ${res.statusCode}).');
      }

      final dir = await getTemporaryDirectory();
      // Nama tetap agar unduhan lama tertimpa, tidak menumpuk.
      final file = File('${dir.path}/moneywork-update.apk');
      final sink = file.openWrite();
      final total = res.contentLength ?? 0;
      var received = 0;

      await for (final chunk in res.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
      await sink.flush();
      await sink.close();
      return file.path;
    } finally {
      client.close();
    }
  }

  /// Buka installer sistem untuk APK pada [path]. Pengguna menyelesaikan
  /// pemasangan lewat dialog Android (perlu izin "pasang aplikasi tak dikenal").
  Future<String?> installApk(String path) async {
    final result = await OpenFilex.open(
      path,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type == ResultType.done) return null;
    return result.message;
  }
}
