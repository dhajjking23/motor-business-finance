import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';

/// DatabaseHelper - Singleton pengelola koneksi & schema SQLite.
///
/// Semua tabel didefinisikan di sini. Gunakan `database` getter untuk
/// mendapatkan instance yang sudah terbuka. Jangan buat instance Database
/// baru di tempat lain — selalu lewat helper ini agar migrasi konsisten.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbDir = await getApplicationDocumentsDirectory();
    final path = join(dbDir.path, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onConfigure: (db) async {
        // Aktifkan foreign key constraint
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // ==========================================================
    // TABEL: periode (pembukuan)
    // ==========================================================
    batch.execute('''
      CREATE TABLE periode (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_periode TEXT NOT NULL,
        tanggal_mulai TEXT NOT NULL,
        tanggal_selesai TEXT,
        status TEXT NOT NULL DEFAULT '${AppConstants.statusPeriodeAktif}',
        modal_awal REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // ==========================================================
    // TABEL: karyawan
    // ==========================================================
    batch.execute('''
      CREATE TABLE karyawan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL UNIQUE,
        is_internal INTEGER NOT NULL DEFAULT 1,
        aktif INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // ==========================================================
    // TABEL: motor
    // ==========================================================
    batch.execute('''
      CREATE TABLE motor (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kode_motor TEXT NOT NULL UNIQUE,
        merk TEXT NOT NULL,
        tipe TEXT NOT NULL,
        tahun INTEGER,
        warna TEXT,
        plat_nomor TEXT,
        tanggal_masuk TEXT NOT NULL,
        harga_beli REAL NOT NULL DEFAULT 0,
        total_modal REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT '${AppConstants.statusMotorTersedia}',
        periode_id INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (periode_id) REFERENCES periode (id) ON DELETE SET NULL
      )
    ''');

    // ==========================================================
    // TABEL: motor_cost (biaya per unit motor)
    // ==========================================================
    batch.execute('''
      CREATE TABLE motor_cost (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        motor_id INTEGER NOT NULL,
        kategori TEXT NOT NULL,
        nominal REAL NOT NULL DEFAULT 0,
        keterangan TEXT,
        tanggal TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (motor_id) REFERENCES motor (id) ON DELETE CASCADE
      )
    ''');

    // ==========================================================
    // TABEL: penjualan
    // ==========================================================
    batch.execute('''
      CREATE TABLE penjualan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        motor_id INTEGER NOT NULL,
        tanggal_jual TEXT NOT NULL,
        harga_jual REAL NOT NULL DEFAULT 0,
        modal_motor REAL NOT NULL DEFAULT 0,
        laba REAL NOT NULL DEFAULT 0,
        penjual TEXT NOT NULL,
        bonus_eligible INTEGER NOT NULL DEFAULT 1,
        periode_id INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (motor_id) REFERENCES motor (id) ON DELETE RESTRICT,
        FOREIGN KEY (periode_id) REFERENCES periode (id) ON DELETE SET NULL
      )
    ''');

    // ==========================================================
    // TABEL: pemasukan
    // ==========================================================
    batch.execute('''
      CREATE TABLE pemasukan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal TEXT NOT NULL,
        kategori TEXT NOT NULL,
        nominal REAL NOT NULL DEFAULT 0,
        keterangan TEXT,
        referensi_id INTEGER,
        periode_id INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (periode_id) REFERENCES periode (id) ON DELETE SET NULL
      )
    ''');

    // ==========================================================
    // TABEL: pengeluaran
    // ==========================================================
    batch.execute('''
      CREATE TABLE pengeluaran (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal TEXT NOT NULL,
        kategori TEXT NOT NULL,
        nominal REAL NOT NULL DEFAULT 0,
        keterangan TEXT,
        referensi_id INTEGER,
        periode_id INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (periode_id) REFERENCES periode (id) ON DELETE SET NULL
      )
    ''');

    // ==========================================================
    // TABEL: kasbon
    // ==========================================================
    batch.execute('''
      CREATE TABLE kasbon (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_karyawan TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        jumlah REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT '${AppConstants.statusKasbonBelumLunas}',
        tanggal_lunas TEXT,
        keterangan TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // ==========================================================
    // TABEL: cash_flow (histori mutasi kas)
    // ==========================================================
    batch.execute('''
      CREATE TABLE cash_flow (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal TEXT NOT NULL,
        tipe TEXT NOT NULL,
        nominal REAL NOT NULL DEFAULT 0,
        referensi TEXT NOT NULL,
        referensi_id INTEGER,
        keterangan TEXT,
        saldo_setelah REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // ==========================================================
    // TABEL: saldo (singleton row - cash & bank saat ini)
    // ==========================================================
    batch.execute('''
      CREATE TABLE saldo (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        cash REAL NOT NULL DEFAULT 0,
        saldo_bank REAL NOT NULL DEFAULT 0,
        modal_total REAL NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    // ==========================================================
    // TABEL: pembagian_laba (histori tutup buku)
    // ==========================================================
    batch.execute('''
      CREATE TABLE pembagian_laba (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        periode_id INTEGER NOT NULL,
        laba_bersih REAL NOT NULL DEFAULT 0,
        bagian_abah REAL NOT NULL DEFAULT 0,
        bagian_iki REAL NOT NULL DEFAULT 0,
        bagian_andri REAL NOT NULL DEFAULT 0,
        bagian_ilham REAL NOT NULL DEFAULT 0,
        total_hadiah_penjualan REAL NOT NULL DEFAULT 0,
        unit_internal_terjual INTEGER NOT NULL DEFAULT 0,
        bonus_per_unit REAL NOT NULL DEFAULT 0,
        detail_bonus_json TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (periode_id) REFERENCES periode (id) ON DELETE CASCADE
      )
    ''');

    // ==========================================================
    // TABEL: audit_log
    // ==========================================================
    batch.execute('''
      CREATE TABLE audit_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tabel TEXT NOT NULL,
        record_id INTEGER,
        aksi TEXT NOT NULL,
        data_lama TEXT,
        data_baru TEXT,
        keterangan TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await batch.commit(noResult: true);

    // Seed data awal
    await _seedInitialData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migrasi versi mendatang ditambahkan di sini secara berurutan,
    // contoh: if (oldVersion < 2) { await db.execute('ALTER TABLE ...'); }
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Seed karyawan default
    for (final nama in AppConstants.karyawanDefault) {
      await db.insert('karyawan', {
        'nama': nama,
        'is_internal': 1,
        'aktif': 1,
        'created_at': now,
      });
    }

    // Seed saldo awal (singleton row id=1)
    await db.insert('saldo', {
      'id': 1,
      'cash': 0,
      'saldo_bank': 0,
      'modal_total': 0,
      'updated_at': now,
    });
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Path fisik file database, dipakai untuk fitur backup/restore.
  Future<String> getDbPath() async {
    final dbDir = await getApplicationDocumentsDirectory();
    return join(dbDir.path, AppConstants.dbName);
  }

  /// Backup database ke file tujuan (path lengkap termasuk nama file).
  Future<File> backupDatabase(String destinationPath) async {
    final db = await database;
    // Pastikan semua perubahan tertulis ke disk sebelum copy
    await db.rawQuery('PRAGMA wal_checkpoint(FULL)');
    final currentPath = await getDbPath();
    final sourceFile = File(currentPath);
    return sourceFile.copy(destinationPath);
  }

  /// Restore database dari file backup. Menutup koneksi aktif dulu.
  Future<void> restoreDatabase(String sourceBackupPath) async {
    await close();
    final currentPath = await getDbPath();
    final backupFile = File(sourceBackupPath);
    await backupFile.copy(currentPath);
    // Buka ulang koneksi
    _database = await _initDatabase();
  }
}
