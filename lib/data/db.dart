import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'specimen.dart';

/// Base de datos local (queda solo en el teléfono).
class LocalDb {
  LocalDb._(this._db, this.photosDir);

  final Database _db;
  final Directory photosDir;

  static Future<LocalDb> open() async {
    final docs = await getApplicationDocumentsDirectory();
    final photos = Directory(p.join(docs.path, 'photos'));
    if (!photos.existsSync()) photos.createSync(recursive: true);

    final db = await openDatabase(
      p.join(docs.path, 'rockbosg.db'),
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE specimens (
            id TEXT PRIMARY KEY,
            mineralId TEXT,
            name TEXT,
            photos TEXT,
            foundAt INTEGER,
            place TEXT,
            lat REAL,
            lng REAL,
            mohs TEXT,
            color TEXT,
            luster TEXT,
            streak TEXT,
            weight TEXT,
            size TEXT,
            notes TEXT,
            favorite INTEGER,
            origin TEXT,
            createdAt INTEGER
          )''');
      },
    );
    return LocalDb._(db, photos);
  }

  File photoFile(String name) => File(p.join(photosDir.path, name));

  Future<List<Specimen>> all() async {
    final rows = await _db.query('specimens', orderBy: 'createdAt DESC');
    return rows.map(Specimen.fromMap).toList();
  }

  Future<void> upsert(Specimen s) => _db.insert('specimens', s.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> delete(Specimen s) async {
    await _db.delete('specimens', where: 'id = ?', whereArgs: [s.id]);
    for (final f in s.photos) {
      final file = photoFile(f);
      if (file.existsSync()) file.deleteSync();
    }
  }
}
