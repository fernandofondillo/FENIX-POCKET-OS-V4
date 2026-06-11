// lib/services/perfil_db_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class PerfilDbService {
  Database? _db;

  Future<void> initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fenix_perfil.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE eav_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            categoria TEXT NOT NULL,
            clave TEXT UNIQUE NOT NULL,
            valor TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> upsertEav(String categoria, String clave, String valor) async {
    if (_db == null) await initDb();
    await _db!.insert(
      'eav_data',
      {'categoria': categoria, 'clave': clave, 'valor': valor},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Recupera toda la identidad EAV como Map<String, String>
  /// Utilizado para inyectar contexto al payload del VPS.
  Future<Map<String, String>?> obtenerEavComoMap() async {
    if (_db == null) await initDb();
    final records = await _db!.query('eav_data');
    final result = <String, String>{};
    for (final r in records) {
      result[r['clave'] as String] = r['valor'] as String;
    }
    return result;
  }
}
