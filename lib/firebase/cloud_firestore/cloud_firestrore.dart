import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Untuk debugPrint
// import 'package:logger/logger.dart'; // Aktifkan jika ingin menggunakan Logger

/// Kelas utilitas untuk berinteraksi dengan Cloud Firestore.
/// Menggunakan pola singleton untuk memastikan hanya ada satu instance.
class CloudFirestoreService {
  CloudFirestoreService._(); // Konstruktor privat untuk singleton

  static final CloudFirestoreService instance = CloudFirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final Logger _logger = Logger(); // Aktifkan jika ingin menggunakan Logger

  /// Mengembalikan instance dari FirebaseFirestore.
  FirebaseFirestore get firestore => _firestore;

  /// Menambahkan dokumen baru ke koleksi.
  ///
  /// Mengembalikan [DocumentReference] dari dokumen yang baru dibuat.
  ///
  /// Contoh:
  /// ```dart
  /// await CloudFirestoreService.instance.addDocument(
  ///   collectionPath: 'users',
  ///   data: {'name': 'John Doe', 'age': 30},
  /// );
  /// ```
  Future<DocumentReference<Map<String, dynamic>>?> addDocument({
    required String collectionPath,
    required Map<String, dynamic> data,
  }) async {
    try {
      final docRef = await _firestore.collection(collectionPath).add(data);
      // _logger.i('Dokumen berhasil ditambahkan ke $collectionPath dengan ID: ${docRef.id}');
      debugPrint(
        'Dokumen berhasil ditambahkan ke $collectionPath dengan ID: ${docRef.id}',
      );
      return docRef;
    } on FirebaseException catch (e) {
      // _logger.e('Gagal menambahkan dokumen ke $collectionPath: ${e.message}');
      debugPrint('Gagal menambahkan dokumen ke $collectionPath: ${e.message}');
      return null;
    } catch (e) {
      // _logger.e('Terjadi kesalahan tidak terduga saat menambahkan dokumen ke $collectionPath: $e');
      debugPrint(
        'Terjadi kesalahan tidak terduga saat menambahkan dokumen ke $collectionPath: $e',
      );
      return null;
    }
  }

  /// Mendapatkan semua dokumen dalam sebuah koleksi.
  ///
  /// Mengembalikan [QuerySnapshot] yang berisi semua dokumen.
  ///
  /// Contoh:
  /// ```dart
  /// final snapshot = await CloudFirestoreService.instance.getCollection(
  ///   collectionPath: 'products',
  /// );
  /// for (var doc in snapshot!.docs) {
  ///   print('${doc.id} => ${doc.data()}');
  /// }
  /// ```
  Future<QuerySnapshot<Map<String, dynamic>>?> getCollection({
    required String collectionPath,
    GetOptions? options,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)?
    queryBuilder,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection(collectionPath);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      final snapshot = await query.get(options);
      // _logger.i('Berhasil mendapatkan ${snapshot.size} dokumen dari $collectionPath');
      debugPrint(
        'Berhasil mendapatkan ${snapshot.size} dokumen dari $collectionPath',
      );
      return snapshot;
    } on FirebaseException catch (e) {
      // _logger.e('Gagal mendapatkan koleksi $collectionPath: ${e.message}');
      debugPrint('Gagal mendapatkan koleksi $collectionPath: ${e.message}');
      return null;
    } catch (e) {
      // _logger.e('Terjadi kesalahan tidak terduga saat mendapatkan koleksi $collectionPath: $e');
      debugPrint(
        'Terjadi kesalahan tidak terduga saat mendapatkan koleksi $collectionPath: $e',
      );
      return null;
    }
  }

  /// Mendapatkan dokumen tunggal berdasarkan ID dokumen.
  ///
  /// Mengembalikan [DocumentSnapshot] dari dokumen.
  ///
  /// Contoh:
  /// ```dart
  /// final doc = await CloudFirestoreService.instance.getDocumentById(
  ///   collectionPath: 'users',
  ///   docId: 'user123',
  /// );
  /// if (doc != null && doc.exists) {
  ///   print('${doc.id} => ${doc.data()}');
  /// }
  /// ```
  Future<DocumentSnapshot<Map<String, dynamic>>?> getDocumentById({
    required String collectionPath,
    required String docId,
    GetOptions? options,
  }) async {
    try {
      final docSnapshot = await _firestore
          .collection(collectionPath)
          .doc(docId)
          .get(options);
      // _logger.i('Berhasil mendapatkan dokumen dengan ID $docId dari $collectionPath');
      debugPrint(
        'Berhasil mendapatkan dokumen dengan ID $docId dari $collectionPath',
      );
      return docSnapshot;
    } on FirebaseException catch (e) {
      // _logger.e('Gagal mendapatkan dokumen $docId dari $collectionPath: ${e.message}');
      debugPrint(
        'Gagal mendapatkan dokumen $docId dari $collectionPath: ${e.message}',
      );
      return null;
    } catch (e) {
      // _logger.e('Terjadi kesalahan tidak terduga saat mendapatkan dokumen $docId dari $collectionPath: $e');
      debugPrint(
        'Terjadi kesalahan tidak terduga saat mendapatkan dokumen $docId dari $collectionPath: $e',
      );
      return null;
    }
  }

  /// Menetapkan atau memperbarui dokumen dengan ID tertentu.
  /// Jika [docId] adalah null, Firestore akan membuat ID dokumen baru.
  /// Jika [merge] adalah true, data yang diberikan akan digabungkan dengan data yang ada.
  ///
  /// Mengembalikan [DocumentReference] dari dokumen yang dimodifikasi.
  ///
  /// Contoh:
  /// ```dart
  /// // Menetapkan dokumen dengan ID tertentu
  /// await CloudFirestoreService.instance.setDocument(
  ///   collectionPath: 'users',
  ///   docId: 'user123',
  ///   data: {'name': 'Jane Doe', 'city': 'New York'},
  /// );
  ///
  /// // Menetapkan dokumen baru dengan ID otomatis
  /// await CloudFirestoreService.instance.setDocument(
  ///   collectionPath: 'orders',
  ///   data: {'item': 'Laptop', 'quantity': 1},
  /// );
  /// ```
  Future<DocumentReference<Map<String, dynamic>>?> setDocument({
    required String collectionPath,
    String? docId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    try {
      final docRef = _firestore.collection(collectionPath).doc(docId);
      await docRef.set(data, SetOptions(merge: merge));
      // _logger.i('Dokumen berhasil ditetapkan di $collectionPath/${docRef.id}');
      debugPrint('Dokumen berhasil ditetapkan di $collectionPath/${docRef.id}');
      return docRef;
    } on FirebaseException catch (e) {
      // _logger.e('Gagal menetapkan dokumen di $collectionPath/${docId ?? 'new'}: ${e.message}');
      debugPrint(
        'Gagal menetapkan dokumen di $collectionPath/${docId ?? 'new'}: ${e.message}',
      );
      return null;
    } catch (e) {
      // _logger.e('Terjadi kesalahan tidak terduga saat menetapkan dokumen di $collectionPath/${docId ?? 'new'}: $e');
      debugPrint(
        'Terjadi kesalahan tidak terduga saat menetapkan dokumen di $collectionPath/${docId ?? 'new'}: $e',
      );
      return null;
    }
  }

  /// Menetapkan atau memperbarui dokumen dengan objek kustom menggunakan converter.
  ///
  /// Mengembalikan [DocumentReference] dari dokumen yang dimodifikasi.
  ///
  /// Contoh penggunaan `City` model (seperti yang Anda berikan):
  /// ```dart
  /// class City {
  ///   final String? name;
  ///   // ... properti lainnya
  ///
  ///   City({this.name, /* ... */});
  ///
  ///   factory City.fromFirestore(
  ///     DocumentSnapshot<Map<String, dynamic>> snapshot,
  ///     SnapshotOptions? options,
  ///   ) {
  ///     final data = snapshot.data();
  ///     return City(name: data?['name'], /* ... */);
  ///   }
  ///
  ///   Map<String, dynamic> toFirestore() {
  ///     return {'name': name, /* ... */};
  ///   }
  /// }
  ///
  /// // Dalam logika Anda:
  /// final newCity = City(name: 'Bandung', country: 'Indonesia');
  /// await CloudFirestoreService.instance.setCustomObject(
  ///   collectionPath: 'cities',
  ///   docId: 'BDG',
  ///   fromFirestore: City.fromFirestore,
  ///   toFirestore: (city, options) => city.toFirestore(),
  ///   data: newCity,
  /// );
  /// ```
  Future<DocumentReference<R>?> setCustomObject<R extends Object?>({
    required String collectionPath,
    String? docId,
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
    required R data,
    bool merge = true,
  }) async {
    try {
      final docRef = _firestore
          .collection(collectionPath)
          .doc(docId)
          .withConverter<R>(
            fromFirestore: fromFirestore,
            toFirestore: toFirestore,
          );

      await docRef.set(data, SetOptions(merge: merge));
      // _logger.i('Objek kustom berhasil ditetapkan di $collectionPath/${docRef.id}');
      debugPrint(
        'Objek kustom berhasil ditetapkan di $collectionPath/${docRef.id}',
      );
      return docRef;
    } on FirebaseException catch (e) {
      // _logger.e('Gagal menetapkan objek kustom di $collectionPath/${docId ?? 'new'}: ${e.message}');
      debugPrint(
        'Gagal menetapkan objek kustom di $collectionPath/${docId ?? 'new'}: ${e.message}',
      );
      return null;
    } catch (e) {
      // _logger.e('Terjadi kesalahan tidak terduga saat menetapkan objek kustom di $collectionPath/${docId ?? 'new'}: $e');
      debugPrint(
        'Terjadi kesalahan tidak terduga saat menetapkan objek kustom di $collectionPath/${docId ?? 'new'}: $e',
      );
      return null;
    }
  }

  /// Memperbarui bidang tertentu dalam dokumen.
  ///
  /// Contoh:
  /// ```dart
  /// await CloudFirestoreService.instance.updateDocument(
  ///   collectionPath: 'users',
  ///   docId: 'user123',
  ///   data: {'age': 31, 'status': 'active'},
  /// );
  /// ```
  Future<void> updateDocument({
    required String collectionPath,
    required String docId,
    required Map<Object, Object?> data,
  }) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).update(data);
      // _logger.i('Dokumen berhasil diperbarui di $collectionPath/$docId');
      debugPrint('Dokumen berhasil diperbarui di $collectionPath/$docId');
    } on FirebaseException catch (e) {
      // _logger.e('Gagal memperbarui dokumen di $collectionPath/$docId: ${e.message}');
      debugPrint(
        'Gagal memperbarui dokumen di $collectionPath/$docId: ${e.message}',
      );
    } catch (e) {
      // _logger.e('Terjadi kesalahan tidak terduga saat memperbarui dokumen di $collectionPath/$docId: $e');
      debugPrint(
        'Terjadi kesalahan tidak terduga saat memperbarui dokumen di $collectionPath/$docId: $e',
      );
    }
  }

  /// Menghapus dokumen dari koleksi.
  ///
  /// Contoh:
  /// ```dart
  /// await CloudFirestoreService.instance.deleteDocument(
  ///   collectionPath: 'products',
  ///   docId: 'productXYZ',
  /// );
  /// ```
  Future<void> deleteDocument({
    required String collectionPath,
    required String docId,
  }) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).delete();
      // _logger.i('Dokumen berhasil dihapus dari $collectionPath/$docId');
      debugPrint('Dokumen berhasil dihapus dari $collectionPath/$docId');
    } on FirebaseException catch (e) {
      // _logger.e('Gagal menghapus dokumen dari $collectionPath/$docId: ${e.message}');
      debugPrint(
        'Gagal menghapus dokumen dari $collectionPath/$docId: ${e.message}',
      );
    } catch (e) {
      // _logger.e('Terjadi kesalahan tidak terduga saat menghapus dokumen dari $collectionPath/$docId: $e');
      debugPrint(
        'Terjadi kesalahan tidak terduga saat menghapus dokumen dari $collectionPath/$docId: $e',
      );
    }
  }

  /// Menambahkan atau memperbarui bidang timestamp di dokumen.
  /// Jika dokumen tidak ada, ia akan dibuat dengan timestamp.
  ///
  /// Contoh:
  /// ```dart
  /// await CloudFirestoreService.instance.addOrUpdateTimestamp(
  ///   collectionPath: 'logs',
  ///   docId: 'event1',
  ///   keyName: 'last_updated',
  /// );
  /// ```
  Future<void> addOrUpdateTimestamp({
    required String collectionPath,
    required String docId,
    String keyName = "timestamp",
  }) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).set({
        keyName: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // _logger.i('Timestamp berhasil ditambahkan/diperbarui di $collectionPath/$docId');
      debugPrint(
        'Timestamp berhasil ditambahkan/diperbarui di $collectionPath/$docId',
      );
    } on FirebaseException catch (e) {
      // _logger.e('Gagal menambahkan/memperbarui timestamp di $collectionPath/$docId: ${e.message}');
      debugPrint(
        'Gagal menambahkan/memperbarui timestamp di $collectionPath/$docId: ${e.message}',
      );
    } catch (e) {
      // _logger.e('Terjadi kesalahan tidak terduga saat menambahkan/memperbarui timestamp di $collectionPath/$docId: $e');
      debugPrint(
        'Terjadi kesalahan tidak terduga saat menambahkan/memperbarui timestamp di $collectionPath/$docId: $e',
      );
    }
  }

  /// Mendapatkan stream dari semua dokumen dalam sebuah koleksi.
  /// Berguna untuk pembaruan real-time.
  ///
  /// Contoh:
  /// ```dart
  /// StreamBuilder<QuerySnapshot?>(
  ///   stream: CloudFirestoreService.instance.streamCollection(collectionPath: 'messages'),
  ///   builder: (context, snapshot) {
  ///     if (snapshot.hasData) {
  ///       return ListView.builder(
  ///         itemCount: snapshot.data!.docs.length,
  ///         itemBuilder: (context, index) {
  ///           final doc = snapshot.data!.docs[index];
  ///           return ListTile(title: Text(doc['text']));
  ///         },
  ///       );
  ///     }
  ///     return CircularProgressIndicator();
  ///   },
  /// );
  /// ```
  Stream<QuerySnapshot<Map<String, dynamic>>?> streamCollection({
    required String collectionPath,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)?
    queryBuilder,
  }) {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection(collectionPath);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      // _logger.i('Mulai streaming koleksi $collectionPath');
      debugPrint('Mulai streaming koleksi $collectionPath');
      return query.snapshots();
    } on FirebaseException catch (e) {
      // _logger.e('Gagal memulai stream koleksi $collectionPath: ${e.message}');
      debugPrint('Gagal memulai stream koleksi $collectionPath: ${e.message}');
      return Stream.value(null);
    } catch (e) {
      // _logger.e('Terjadi kesalahan tidak terduga saat memulai stream koleksi $collectionPath: $e');
      debugPrint(
        'Terjadi kesalahan tidak terduga saat memulai stream koleksi $collectionPath: $e',
      );
      return Stream.value(null);
    }
  }

  /// Mendapatkan stream dari dokumen tunggal.
  /// Berguna untuk pembaruan real-time dari dokumen tertentu.
  ///
  /// Contoh:
  /// ```dart
  /// StreamBuilder<DocumentSnapshot?>(
  ///   stream: CloudFirestoreService.instance.streamDocument(
  ///     collectionPath: 'users',
  ///     docId: 'userABC',
  ///   ),
  ///   builder: (context, snapshot) {
  ///     if (snapshot.hasData && snapshot.data!.exists) {
  ///       return Text('Nama: ${snapshot.data!['name']}');
  ///     }
  ///     return Text('Loading...');
  ///   },
  /// );
  /// ```
  Stream<DocumentSnapshot<Map<String, dynamic>>?> streamDocument({
    required String collectionPath,
    required String docId,
  }) {
    try {
      // _logger.i('Mulai streaming dokumen $docId dari $collectionPath');
      debugPrint('Mulai streaming dokumen $docId dari $collectionPath');
      return _firestore.collection(collectionPath).doc(docId).snapshots();
    } on FirebaseException catch (e) {
      // _logger.e('Gagal memulai stream dokumen $docId dari $collectionPath: ${e.message}');
      debugPrint(
        'Gagal memulai stream dokumen $docId dari $collectionPath: ${e.message}',
      );
      return Stream.value(null);
    } catch (e) {
      // _logger.e('Terjadi kesalahan tidak terduga saat memulai stream dokumen $docId dari $collectionPath: $e');
      debugPrint(
        'Terjadi kesalahan tidak terduga saat memulai stream dokumen $docId dari $collectionPath: $e',
      );
      return Stream.value(null);
    }
  }
}
