import 'dart:io';

import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:http_cache_hive_store/http_cache_hive_store.dart';
import 'package:path_provider/path_provider.dart';

class CacheInterceptor {
  const CacheInterceptor._();

  static Future<CacheStore> _initializeCacheStorage() async {
    // FileCacheStore()
    // MemCacheStore()
    // DbCacheStore(databasePath: dir.path, logStatements: true);
    final Directory tempDir = await getTemporaryDirectory();
    return HiveCacheStore(tempDir.path);
  }

  static Future<CacheOptions> get cacheOptions async => CacheOptions(
    store:
        await _initializeCacheStorage(), // WAJIB: Store yang akan digunakan untuk menyimpan cache
    // Kebijakan Cache:
    // CachePolicy.request adalah default yang paling seimbang dan aman.
    // - Jika ada respons yang valid dan belum basi di cache, gunakan itu.
    // - Jika tidak ada atau sudah basi, lakukan permintaan jaringan.
    // - Jika server merespons dengan 304 Not Modified, gunakan data cache.
    // Ini memastikan data relatif baru sambil tetap memanfaatkan cache.
    policy: CachePolicy.request,

    // Penanganan Kesalahan:
    // hitCacheOnErrorExcept: Jangan kembalikan dari cache jika terjadi error dengan status kode ini.
    // 401 (Unauthorized) dan 403 (Forbidden) biasanya berarti sesi tidak valid atau tidak ada izin.
    // Mengembalikan data cache dalam kasus ini bisa menyesatkan atau menyembunyikan masalah otentikasi.
    // TokenInterceptor Anda akan menangani 401 untuk refresh token.
    hitCacheOnErrorCodes: [401, 403],

    // Mode Offline:
    // hitCacheOnNetworkFailure: true memungkinkan aplikasi untuk mengembalikan data dari cache
    // jika tidak ada koneksi jaringan atau terjadi kesalahan jaringan lainnya.
    // Ini sangat meningkatkan pengalaman pengguna di lingkungan offline/tidak stabil.
    hitCacheOnNetworkFailure: true,

    // Toleransi Data Basi (Stale Data):
    // maxStale: Durasi maksimal di mana respons yang sudah "basi" (misalnya, melewati max-age server)
    // masih dapat dikembalikan dari cache. Ini berfungsi sebagai fallback jika tidak ada koneksi
    // atau server tidak merespons. Setelah durasi ini, data akan dianggap tidak valid.
    // 7 hari adalah nilai yang masuk akal untuk fallback, Anda bisa menyesuaikannya.
    maxStale: const Duration(days: 7),

    // Prioritas Cache:
    // CachePriority.normal adalah default. Anda bisa mengatur high/low jika ada data yang lebih krusial.
    priority: CachePriority.normal,

    // Mengizinkan Caching untuk Metode POST:
    // allowPostMethod: false adalah default dan disarankan.
    // Permintaan POST biasanya mengubah status di server dan tidak boleh di-cache
    // karena bisa menyebabkan perilaku yang tidak terduga atau data yang tidak konsisten.
    // Ubah ke true hanya jika Anda yakin POST Anda idempotent dan aman untuk di-cache.
    allowPostMethod: false,

    // Enkripsi Cache (Opsional dan Kompleks):
    // cipher: null adalah default. Jika Anda menyimpan data yang sangat sensitif di cache
    // dan membutuhkan enkripsi saat data diam (at rest), Anda bisa menyediakan implementasi
    // CacheCipher kustom di sini. Namun, ini menambah kompleksitas dan harus dilakukan
    // dengan pemahaman yang mendalam tentang kriptografi. Untuk sebagian besar kasus,
    // HTTPS (enkripsi saat transit) dan penyimpanan token yang aman (FlutterSecureStorage)
    // sudah cukup.
    cipher: null,

    // Key Builder (Opsional):
    // keyBuilder: CacheOptions.defaultCacheKeyBuilder,
    // Memungkinkan Anda untuk menyesuaikan cara kunci cache dibuat dari RequestOptions.
    // Defaultnya sudah cukup baik untuk sebagian besar kasus.
  );
}
