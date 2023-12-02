import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

import 'crud_exceptions.dart';

class NotesService {
  Database? _db;

  List<DatabaseNote> _notes = [];

  NotesService._sharedInstance();

  static final NotesService _shared = NotesService._sharedInstance();

  factory NotesService() {
    return _shared;
  }

  final _notesStreamController =
      StreamController<List<DatabaseNote>>.broadcast();

  Stream<List<DatabaseNote>> get allNotes => _notesStreamController.stream;

  Future<DatabaseUser> getOrCreateuser({
    required String email,
  }) async {
    await ensureDBIsOpen();
    try {
      final user = await getUser(email: email);
      return user;
    } on CouldNotFindUserException {
      return createUser(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _cacheNotes() async {
    final allNotes = await getAllNotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }

  Future<DatabaseNote> createNote({
    required DatabaseUser owner,
  }) async {
    await ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final dbUser = await getUser(email: owner.email);

    if (dbUser != owner) {
      throw CouldNotFindUserException();
    }

    const text = '';
    final noteId = await db.insert(noteTable, {
      userIdColumn: owner.id,
      textColumn: '',
      isSyncedColumn: 1,
    });

    final note =
        DatabaseNote(id: noteId, userId: owner.id, text: text, isSynced: true);

    _notes.add(note);
    _notesStreamController.add(_notes);

    return note;
  }

  Future<DatabaseNote> getNote({
    required int id,
  }) async {
    await ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      noteTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (notes.isEmpty) {
      throw CouldNotFindnoteException();
    } else {
      final note = DatabaseNote.fromRow(notes.first);

      _notes.removeWhere((note) => note.id == id);
      _notes.add(note);
      _notesStreamController.add(_notes);
      return note;
    }
  }

  Future<Iterable<DatabaseNote>> getAllNotes() async {
    await ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(noteTable);
    return notes.map((o) => DatabaseNote.fromRow(o));
  }

  Future<DatabaseNote> updateNote({
    required DatabaseNote note,
    required String text,
  }) async {
    final db = _getDatabaseOrThrow();
    await getNote(id: note.id);

    final updateCount = await db.update(noteTable, {
      textColumn: text,
      isSyncedColumn: 0,
    });

    if (updateCount == 0) {
      throw CouldNotUpdateNoteException();
    } else {
      final updatedNote = await getNote(
        id: note.id,
      );

      _notes.removeWhere((note) => note.id == updatedNote.id);
      _notes.add(updatedNote);
      _notesStreamController.add(_notes);
      return updatedNote;
    }
  }

  Future<void> deleteNote({
    required int id,
  }) async {
    await ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      noteTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (deletedCount == 0) {
      throw CouldNotDeleteNoteException();
    }
    {
      _notes.removeWhere((note) => note.id == id);
      _notesStreamController.add(_notes);
    }
  }

  Future<int> deleteAllNotes() async {
    await ensureDBIsOpen();

    final db = _getDatabaseOrThrow();
    final numberOfDeletions = await db.delete(noteTable);

    _notes = [];
    _notesStreamController.add(_notes);

    return numberOfDeletions;
  }

  Database _getDatabaseOrThrow() {
    final db = _db;

    if (db == null) {
      throw DatabaseIsNotOpenException();
    } else {
      return db;
    }
  }

  Future<void> close() async {
    await ensureDBIsOpen();
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpenException();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> ensureDBIsOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpenException {
      //empty
    }
  }

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;

      //Create User Tables
      db.execute(createUserTable);
      db.execute(createNoteTable);

      await _cacheNotes();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectoryExeption();
    }
  }

  Future<void> deleteUser({
    required String email,
  }) async {
    await ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      userTable,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (deletedCount != 1) {
      throw CouldNotDeleteUserException();
    }
  }

  Future<DatabaseUser> createUser({required String email}) async {
    await ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isNotEmpty) {
      throw UserAlreadyExistsException();
    }

    final userId = await db.insert(userTable, {
      emailColumn: email.toLowerCase(),
    });

    return DatabaseUser(email: email, id: userId);
  }

  Future<DatabaseUser> getUser({required String email}) async {
    await ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isEmpty) {
      throw CouldNotFindUserException();
    } else {
      return DatabaseUser.fromRow(results.first);
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

  DatabaseUser.fromRow(Map<String, Object?> map)
      : id = map['idColumn'] as int,
        email = map['emailColumn'] as String;

  @override
  String toString() {
    return 'Person, ID = $id, email = $email';
  }

  @override
  bool operator ==(covariant DatabaseUser other) {
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}

class DatabaseNote {
  final int id;
  final int userId;
  final String text;
  final bool isSynced;

  DatabaseNote({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSynced,
  });
  DatabaseNote.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        text = map[textColumn] as String,
        isSynced = (map[isSyncedColumn] as int) == 1 ? true : false;

  @override
  String toString() {
    return 'Note, ID = $id, userId = $userId, isSynced = $isSynced';
  }

  @override
  bool operator ==(covariant DatabaseNote other) {
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}

const dbName = 'notes.db';
const userTable = 'users';
const noteTable = 'note';
const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'userId';
const textColumn = 'text';
const isSyncedColumn = 'isSynced';

const createNoteTable = '''
        CREATE TABLE IF NOT EXISTS "note" (
          "id"	INTEGER NOT NULL UNIQUE,
          "user_id"	INTEGER NOT NULL,
          "text"	TEXT,
          "is_synced"	INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY("user_id") REFERENCES "user"("id"),
          PRIMARY KEY("id" AUTOINCREMENT)
        ); ''';

const createUserTable = ''' 
      CREATE TABLE IF NOT EXISTS "user" (
	    "id"	INTEGER NOT NULL UNIQUE,
	    "email"	TEXT NOT NULL UNIQUE,
	    PRIMARY KEY("id" AUTOINCREMENT)
      );''';
