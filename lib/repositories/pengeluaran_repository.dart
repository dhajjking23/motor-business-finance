import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../core/constants/app_constants.dart';
import '../models/pengeluaran_model.dart';
import 'audit_log_repository.dart';
import 'saldo_repository.dart';

/// Repository pengeluaran umum (BUKAN untuk kasbon — kasbon punya
/// repository & logika piutang tersendiri di KasbonRepository, karena
/// kasbon bukan kerugian melainkan piutang karyawan).
class PengeluaranRepository {
  final Database db;

  PengeluaranRepository(this.db);

  Future<PengeluaranModel> tambahPengeluaran({
    required DateTime tanggal,
    required String kategori,
    required double nominal,
    String? keterangan,
    int? periodeId,
    int? referensiId,
  }) async {
    return db.transaction<PengeluaranModel>((txn) async {
      final auditLog = AuditLogRepository(txn);
      final saldoRepo = SaldoRepository(txn);
      final now = DateTime.now();

      final pengeluaran = PengeluaranModel(
        tanggal: tanggal,
        kategori: kategori,
        nominal: nominal,
        keterangan: keterangan,
        referensiId: referensiId,
        periodeId: periodeId,
        createdAt: now,
      );
      final id = await txn.insert('pengeluaran', pengeluaran.toMap());
      final saved =
          PengeluaranModel.fromMap({...pengeluaran.toMap(), 'id': id});

      await auditLog.catatCreate(
          'pengeluaran', id, jsonEncode(saved.toMap()));

      await saldoRepo.mutasiCash(
        nominal: nominal,
        tipe: AppConstants.cashFlowKeluar,
        referensi: AppConstants.cashFlowRefPengeluaran,
        referensiId: id,
        keterangan: keterangan ?? kategori,
        tanggal: tanggal,
      );

      return saved;
    });
  }

  Future<List<PengeluaranModel>> getAll(
      {int? periodeId, String? kategori}) async {
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];
    if (periodeId != null) {
      whereClauses.add('periode_id = ?');
      whereArgs.add(periodeId);
    }
    if (kategori != null) {
      whereClauses.add('kategori = ?');
      whereArgs.add(kategori);
    }
    final result = await db.query(
      'pengeluaran',
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'tanggal DESC',
    );
    return result.map((e) => PengeluaranModel.fromMap(e)).toList();
  }

  /// Total pengeluaran "Pengeluaran Lain" saja (dipakai untuk hitung laba
  /// bersih periode — Kasbon TIDAK mengurangi laba karena itu piutang).
  Future<double> getTotalPengeluaranLain({int? periodeId}) async {
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(nominal), 0) as total FROM pengeluaran
      WHERE kategori = 'Pengeluaran Lain'
      ${periodeId != null ? "AND periode_id = ?" : ""}
    ''', periodeId != null ? [periodeId] : []);
    return (result.first['total'] as num).toDouble();
  }
}
