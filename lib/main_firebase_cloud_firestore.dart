import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase/cloud_firestore/cloud_firestrore.dart';
import 'firebase_options.dart';

class TodoItem {
  final String? id;
  final String title;
  final bool isDone;
  final Timestamp? createdAt;

  TodoItem({this.id, required this.title, this.isDone = false, this.createdAt});

  /// Factory constructor untuk membuat instance [TodoItem] dari [DocumentSnapshot].
  factory TodoItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return TodoItem(
      id: snapshot.id, // ID dokumen Firestore
      title: data?['title'] as String? ?? '',
      isDone: data?['isDone'] as bool? ?? false,
      createdAt: data?['createdAt'] as Timestamp?,
    );
  }

  /// Mengubah instance [TodoItem] menjadi [Map<String, dynamic>]
  /// yang siap untuk disimpan ke Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'isDone': isDone,
      'createdAt':
          createdAt ??
          FieldValue.serverTimestamp(), // Menambahkan timestamp saat dibuat
    };
  }

  /// Metode copyWith untuk membuat instance baru dari TodoItem dengan nilai yang diubah.
  TodoItem copyWith({
    String? id,
    String? title,
    bool? isDone,
    Timestamp? createdAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Import file layanan Firestore dan model TodoItem yang kita buat

// Impor firebase_options.dart jika Anda telah menjalankan `flutterfire configure`
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Pastikan Flutter binding sudah diinisialisasi
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions
        .currentPlatform, // Aktifkan jika menggunakan flutterfire configure
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Todo Firestore',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false, // Sembunyikan banner debug
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _todoController = TextEditingController();
  static const String _collectionPath = 'todos'; // Nama koleksi Firestore

  @override
  void dispose() {
    _todoController.dispose();
    super.dispose();
  }

  /// Menampilkan dialog untuk menambahkan atau mengedit tugas.
  Future<void> _showTodoDialog({TodoItem? todo}) async {
    _todoController.text = todo?.title ?? ''; // Isi teks jika mengedit

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(todo == null ? 'Tambah Tugas Baru' : 'Edit Tugas'),
          content: TextField(
            controller: _todoController,
            decoration: const InputDecoration(
              hintText: 'Masukkan tugas...',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                _todoController.clear(); // Bersihkan controller setelah batal
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_todoController.text.isNotEmpty) {
                  if (todo == null) {
                    _addTodo(); // Panggil fungsi tambah jika tugas baru
                  } else {
                    _updateTodo(
                      todo.id!,
                      _todoController.text,
                    ); // Panggil fungsi update jika edit
                  }
                  Navigator.of(context).pop(); // Tutup dialog setelah berhasil
                  _todoController.clear(); // Bersihkan controller
                }
              },
              child: Text(todo == null ? 'Tambah' : 'Simpan'),
            ),
          ],
        );
      },
    );
  }

  /// Fungsi untuk menambahkan tugas baru ke Firestore.
  Future<void> _addTodo() async {
    final newTodo = TodoItem(
      title: _todoController.text,
      isDone: false,
      createdAt: Timestamp.now(), // Tambahkan timestamp saat dibuat
    );
    await CloudFirestoreService.instance.setCustomObject<TodoItem>(
      collectionPath: _collectionPath,
      data: newTodo,
      fromFirestore: TodoItem.fromFirestore,
      toFirestore: (todo, options) => todo.toFirestore(),
    );
    _todoController.clear(); // Bersihkan input setelah menambahkan
  }

  /// Fungsi untuk memperbarui tugas yang sudah ada di Firestore.
  Future<void> _updateTodo(String todoId, String newTitle) async {
    await CloudFirestoreService.instance.updateDocument(
      collectionPath: _collectionPath,
      docId: todoId,
      data: {'title': newTitle},
    );
  }

  /// Fungsi untuk mengubah status selesai/belum selesai dari tugas.
  Future<void> _toggleTodoStatus(TodoItem todo) async {
    await CloudFirestoreService.instance.updateDocument(
      collectionPath: _collectionPath,
      docId: todo.id!,
      data: {'isDone': !todo.isDone},
    );
  }

  /// Fungsi untuk menghapus tugas dari Firestore.
  Future<void> _deleteTodo(String todoId) async {
    await CloudFirestoreService.instance.deleteDocument(
      collectionPath: _collectionPath,
      docId: todoId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplikasi Todo Firestore'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Bagian input untuk menambahkan tugas baru
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _todoController,
                    decoration: const InputDecoration(
                      labelText: 'Apa yang perlu dilakukan?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                    ),
                    onSubmitted: (_) =>
                        _addTodo(), // Tambahkan saat enter ditekan
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _showTodoDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Bagian untuk menampilkan daftar tugas (dengan pembaruan real-time)
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>?>(
              stream: CloudFirestoreService.instance.streamCollection(
                collectionPath: _collectionPath,
                queryBuilder: (query) => query.orderBy(
                  'createdAt',
                  descending: true,
                ), // Urutkan berdasarkan waktu pembuatan
              ),
              builder: (context, snapshot) {
                // Menampilkan indikator loading jika data masih dimuat
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Menampilkan pesan error jika terjadi kesalahan
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Terjadi kesalahan: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // Menampilkan pesan jika tidak ada data
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Tidak ada tugas. Ayo tambahkan satu!',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                // Membangun daftar tugas dari data Firestore
                final todos = snapshot.data!.docs.map((doc) {
                  return TodoItem.fromFirestore(
                    doc,
                    null, // SnapshotOptions tidak diperlukan di sini
                  );
                }).toList();

                return ListView.builder(
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: Checkbox(
                          value: todo.isDone,
                          onChanged: (bool? newValue) {
                            if (todo.id != null) {
                              _toggleTodoStatus(todo);
                            }
                          },
                        ),
                        title: Text(
                          todo.title,
                          style: TextStyle(
                            decoration: todo.isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: todo.isDone ? Colors.grey : Colors.black,
                          ),
                        ),
                        subtitle: todo.createdAt != null
                            ? Text(
                                'Dibuat: ${todo.createdAt!.toDate().toLocal().toString().split('.')[0]}', // Format tanggal
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showTodoDialog(
                                todo: todo,
                              ), // Panggil dialog untuk edit
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                if (todo.id != null) {
                                  _deleteTodo(todo.id!);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showTodoDialog(), // Tombol FAB untuk menambah tugas baru
        tooltip: 'Tambah Tugas',
        child: const Icon(Icons.add),
      ),
    );
  }
}
