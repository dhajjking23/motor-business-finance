import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../core/constants/app_constants.dart';
import '../models/kasbon_model.dart';
import 'audit_log_repository.dart';
import 'saldo_repository.dart';

/// Repository kasbon karyawan.
///
/// KONSEP PENTING: Kasbon adalah PIUTANG karyawan, bukan kerugian usaha.
/// - Saat kasbon diambil: cash berkurang, piutang karyawan bertambah.
/// - Saat kasbon dibayar/lunas: cash bertambah, piutang berkurang.
/// - Kasbon TIDAK mengurangi laba bersih periode (lihat PengeluaranRepository
///   yang hanya menjumlahkan kategori 'Pengeluaran Lain').
class KasbonRepository {
  final Database db;

  KasbonRepository(this.db);

  Future<KasbonModel> ambilKasbon({
    required String namaKaryawan,
    required DateTime tanggal,
    required double jumlah,
    String? keterangan,
  }) async {
    return db.transaction<KasbonModel>((txn) async {
      final auditLog = AuditLogRepository(txn);
      final saldoRepo = SaldoRepository(txn);
      final now = DateTime.now();

      final kasbon = KasbonModel(
        namaKaryawan: namaKaryawan,
        tanggal: tanggal,
        jumlah: jumlah,
        status: AppConstants.statusKasbonBelumLunas,
        keterangan: keterangan,
        createdAt: now,
        updatedAt: now,
      );
      final id = await txn.insert('kasbon', kasbon.toMap());
      final saved = KasbonModel.fromMap({...kasbon.toMap(), 'id': id});

      await auditLog.catatCreate('kasbon', id, jsonEncode(saved.toMap()),
          keterangan: 'Kasbon $namaKaryawan');

      // Cash berkurang (piutang bertambah, dicatat sebagai referensi KASBON)
      await saldoRepo.mutasiCash(
        nominal: jumlah,
        tipe: AppConstants.cashFlowKeluar,
        referensi: AppConstants.cashFlowRefKasbonAmbil,
        referensiId: id,
        keterangan: 'Kasbon $namaKaryawan',
        tanggal: tanggal,
      );

      return saved;
    });
  }

  Future<KasbonModel> bayarKasbon(int kasbonId, {DateTime? tanggalLunas}) async {
    return db.transaction<KasbonModel>((txn) async {
      final auditLog = AuditLogRepository(txn);
      final saldoRepo = SaldoRepository(txn);

      final result =
          await txn.query('kasbon', where: 'id = ?', whereArgs: [kasbonId]);
      if (result.isEmpty) throw ArgumentError('Data kasbon tidak ditemukan');
      final kasbonLama = KasbonModel.fromMap(result.first);

      if (kasbonLama.isLunas) {
        throw StateError('Kasbon ini sudah lunas.');
      }

      final now = DateTime.now();
      final kasbonBaru = kasbonLama.copyWith(
        status: AppConstants.statusKasbonLunas,
        tanggalLunas: tanggalLunas ?? now,
        updatedAt: now,
      );
      await txn.update('kasbon', kasbonBaru.toMap(),
          where: 'id = ?', whereArgs: [kasbonId]);

      await auditLog.catatUpdate(
        'kasbon',
        kasbonId,
        jsonEncode(kasbonLama.toMap()),
        jsonEncode(kasbonBaru.toMap()),
        keterangan: 'Pelunasan kasbon ${kasbonLama.namaKaryawan}',
      );

      // Cash bertambah kembali (piutang lunas)
      await saldoRepo.mutasiCash(
        nominal: kasbonLama.jumlah,
        tipe: AppConstants.cashFlowMasuk,
        referensi: AppConstants.cashFlowRefKasbonBayar,
        referensiId: kasbonId,
        keterangan: 'Pelunasan kasbon ${kasbonLama.namaKaryawan}',
        tanggal: tanggalLunas,
      );

      return kasbonBaru;
    });
  }

  Future<List<KasbonModel>> getAll({String? namaKaryawan, String? status}) async {
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];
    if (namaKaryawan != null) {
      whereClauses.add('nama_karyawan = ?');
      whereArgs.add(namaKaryawan);
    }
    if (status != null) {
      whereClauses.add('status = ?');
      whereArgs.add(status);
    }
    final result = await db.query(
      'kasbon',
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'tanggal DESC',
    );
    return result.map((e) => KasbonModel.fromMap(e)).toList();
  }

  /// Total piutang kasbon yang belum lunas (untuk Dashboard).
  Future<double> getTotalPiutangBelumLunas() async {
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(jumlah), 0) as total FROM kasbon
      WHERE status = ?
    ''', [AppConstants.statusKasbonBelumLunas]);
    return (result.first['total'] as num).toDouble();
  }

  Future<Map<String, double>> getPiutangPerKaryawan() async {
    final result = await db.rawQuery('''
      SELECT nama_karyawan, COALESCE(SUM(jumlah), 0) as total
      FROM kasbon WHERE status = ?
      GROUP BY nama_karyawan
    ''', [AppConstants.statusKasbonBelumLunas]);

    final map = <String, double>{};
    for (final row in result) {
      map[row['nama_karyawan'] as String] = (row['total'] as num).toDouble();
    }
    return map;
  }
}
