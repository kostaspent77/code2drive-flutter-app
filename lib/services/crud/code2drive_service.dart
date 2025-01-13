import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:code2drive/services/crud/crud_exceptions.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;

class Code2driveService {
  Database? _db;

  Future<DatabaseC2d> updateC2d({
    required DatabaseC2d c2d,
    required String text,
  }) async {
//    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // make sure note exists
    await getC2d(id: c2d.id);

    // update DB
    final updatesCount = await db.update(
      c2dTable,
      {
        textColumn: text,
        isSyncedWithCloudColumn: 0,
      },
      where: 'id = ?',
      whereArgs: [c2d.id],
    );

    if (updatesCount == 0) {
      throw CouldNotUpdateNote();
    } else {
      final updatedC2d = await getC2d(id: c2d.id);
//      _notes.removeWhere((note) => note.id == updatedNote.id);
//      _notes.add(updatedNote);
//      _notesStreamController.add(_notes);
      return updatedC2d;
    }
  }

  Future<Iterable<DatabaseC2d>> getAllCode2Drive() async {
//     await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final code2Drive = await db.query(c2dTable);
    return code2Drive.map((c2dRow) => DatabaseC2d.fromRow(c2dRow));
  }

  Future<DatabaseC2d> getC2d({required int id}) async {
//    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final code2Drive = await db.query(
      c2dTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (code2Drive.isEmpty) {
      throw CouldNotFindC2d();
    } else {
      final c2d = DatabaseC2d.fromRow(code2Drive.first);
//      _notes.removeWhere((note) => note.id == id);
//      _notes.add(note);
//      _notesStreamController.add(_notes);
      return c2d;
    }
  }

  Future<int> deleteAllCode2Drive() async {
//    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final numberOfDeletions = await db.delete(c2dTable);
//    _notes = [];
//    _notesStreamController.add(_notes);
    return numberOfDeletions;
  }

  Future<void> deleteNote({required int id}) async {
//     await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      c2dTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deletedCount == 0) {
      throw CouldNotDeleteC2d();
    } else {
//      _notes.removeWhere((note) => note.id == id);
//      _notesStreamController.add(_notes);
    }
  }

  Future<DatabaseC2d> createNote({required DatabaseUser owner}) async {
//    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // make sure owner exists in the database with the correct id
    final dbUser = await getUser(email: owner.email);
    if (dbUser != owner) {
      throw CouldNotFindUser();
    }

    const text = '';
    // create the c2d 
    final c2dId = await db.insert(c2dTable, {
      userIdColumn: owner.id,
      textColumn: text,
      isSyncedWithCloudColumn: 1,
    });

    final c2d = DatabaseC2d(
      id: c2dId,
      userId: owner.id,
      text: text,
      isSyncedWithCloud: true,
    );

//    _code2Drive.add(c2d);
//    _code2DriveStreamController.add(_code2Drive);

    return c2d;
  }

  Future<DatabaseUser> getUser({required String email}) async {
//    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (results.isEmpty) {
      throw CouldNotFindUser();
    } else {
      return DatabaseUser.fromRow(results.first);
    }
  }
  
  Future<DatabaseUser> createUser({required String email}) async {
//     await _ensureDbIsOpen();
     final db = _getDatabaseOrThrow();
     final results = await db.query(
       userTable,
       limit: 1,
       where: 'email = ?',
       whereArgs: [email.toLowerCase()],
     );
     if (results.isNotEmpty) {
       throw UserAlreadyExists();
     }

     final userId = await db.insert(userTable, {
       emailColumn: email.toLowerCase(),
     });

     return DatabaseUser(
       id: userId,
       email: email,
     );
   }

  Future<void> deleteUser({required String email}) async {
    //await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      userTable,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteUser();
    }
   }

  Database _getDatabaseOrThrow() {
     final db = _db;
     if (db == null) {
       throw DatabaseIsNotOpen();
     } else {
       return db;
     }
   }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> open () async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;
      // create the user table
      await db.execute(createUserTable);
      // create c2d table
      await db.execute(createC2dTable);
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectory();
    }
  }
}

@immutable
class DatabaseUser {
   final int id;
   final String email;
   const DatabaseUser({
     required this.id,
     required this.email,
   });

  DatabaseUser.fromRow(Map<String, Object?> map) :
    id = map[idColumn] as int,
    email = map[emailColumn] as String;

  @override
  String toString() => 'Person, ID = $id, email = $email';

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseC2d {
  final int id;
  final int userId;
  final String text;
  final bool isSyncedWithCloud;

  DatabaseC2d({
    required this.id, 
    required this.userId, 
    required this.text, 
    required this.isSyncedWithCloud,
  });

  DatabaseC2d.fromRow(Map<String, Object?> map) :
    id = map[idColumn] as int,
    userId = map[userIdColumn] as int, 
    text = map[textColumn] as String,
    isSyncedWithCloud = (map[isSyncedWithCloudColumn] as int) == 1 ? true : false;

  @override
   String toString() =>
       'C2d, ID = $id, userId = $userId, isSyncedWithCloud = $isSyncedWithCloud, text = $text';

   @override
   bool operator ==(covariant DatabaseC2d other) => id == other.id;

   @override
   int get hashCode => id.hashCode;

}

class TrafficSigns {
  final int id;
  final String image;
  final String description;
  final String right;
  final String wrong1;
  final String wrong2;
  final String signtitle;

  TrafficSigns({
    required this.id, 
    required this.image, 
    required this.description, 
    required this.right,
    required this.wrong1,
    required this.wrong2,
    required this.signtitle,
  });
}

const dbName = 'code2drive.db';
const c2dTable = 'c2d';
const userTable = 'user';
const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'user_id';
const textColumn = 'text';
const isSyncedWithCloudColumn = 'is_synced_with_cloud';
const createUserTable = '''CREATE TABLE IF NOT EXISTS "user" (
        "id"	INTEGER NOT NULL,
        "email"	TEXT NOT NULL UNIQUE,
        PRIMARY KEY("id" AUTOINCREMENT)
      );''';
const createC2dTable = '''CREATE TABLE IF NOT EXISTS "c2d" (
        "id"	INTEGER NOT NULL,
        "user_id"	INTEGER NOT NULL,
        "text"	INTEGER NOT NULL,
        "is_sunced_with_cloud"	INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY("id" AUTOINCREMENT),
        FOREIGN KEY("user_id") REFERENCES "user"("id")
      );''';

const createTrafficSignsTable = '''CREATE TABLE "traffic_signs" (
        "id"	INTEGER NOT NULL,
        "image"	TEXT NOT NULL,
        "description"	TEXT NOT NULL,
        "right"	TEXT NOT NULL,
        "wrong 1"	TEXT NOT NULL,
        "wrong 2"	TEXT NOT NULL,
        "sign_title"	TEXT NOT NULL,
        PRIMARY KEY("id" AUTOINCREMENT)
      );''';