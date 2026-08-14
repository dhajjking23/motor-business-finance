import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../core/constants/app_constants.dart';
import '../models/pemasukan_model.dart';
import 'audit_log_repository.dart';
import 'saldo_repository.dart';

/// Repository pemasukan manual (di luar penjualan motor otomatis).
/// Kategori 'Tambah Modal' juga menambah modal_total di tabel saldo.
class PemasukanRepository {
  final Database db;

  PemasukanRepository(this.db);

  Future<PemasukanModel> tambahPemasukan({
    required DateTime tanggal,
    required String kategori,
    required double nominal,
    String? keterangan,
    int? periodeId,
  }) async {
    return db.transaction<PemasukanModel>((txn) async {
      final auditLog = AuditLogRepository(txn);
      final saldoRepo = SaldoRepository(txn);
      final now = DateTime.now();

      final pemasukan = PemasukanModel(
        tanggal: tanggal,
        kategori: kategori,
        nominal: nominal,
        keterangan: keterangan,
        periodeId: periodeId,
        createdAt: now,
      );
      final id = await txn.insert('pemasukan', pemasukan.toMap());
      final saved = PemasukanModel.fromMap({...pemasukan.toMap(), 'id': id});

      await auditLog.catatCreate('pemasukan', id, jsonEncode(saved.toMap()));

      if (kategori == 'Tambah Modal') {
        await saldoRepo.tambahModal(nominal, keterangan: keterangan);
      } else {
        await saldoRepo.mutasiCash(
          nominal: nominal,
          tipe: AppConstants.cashFlowMasuk,
          referensi: AppConstants.cashFlowRefPemasukan,
          referensiId: id,
          keterangan: keterangan ?? kategori,
          tanggal: tanggal,
        );
      }

      return saved;
    });
  }

  Future<List<PemasukanModel>> getAll({int? periodeId, String? kategori}) async {
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
      'pemasukan',
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'tanggal DESC',
    );
    return result.map((e) => PemasukanModel.fromMap(e)).toList();
  }

  Future<double> getTotalByKategori(String kategori, {int? periodeId}) async {
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(nominal), 0) as total FROM pemasukan
      WHERE kategori = ? ${periodeId != null ? "AND periode_id = ?" : ""}
    ''', periodeId != null ? [kategori, periodeId] : [kategori]);
    return (result.first['total'] as num).toDouble();
  }
}
