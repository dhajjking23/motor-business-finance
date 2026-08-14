import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../core/constants/app_constants.dart';
import '../models/motor_model.dart';
import '../models/penjualan_model.dart';
import '../models/pemasukan_model.dart';
import 'audit_log_repository.dart';
import 'saldo_repository.dart';

/// Repository penjualan motor.
///
/// ATURAN CALO (wajib dipatuhi, jangan diubah tanpa instruksi eksplisit):
/// - Jika penjual == 'Calo': motor tetap TERJUAL, laba tetap dihitung
///   dan tetap masuk laba bersih periode, TAPI bonus_eligible = false
///   sehingga Calo tidak ikut pembagian hadiah penjualan 10%.
/// - Fee/komisi calo TIDAK dicatat di sistem manapun (dianggap transaksi
///   di luar perusahaan, murni urusan antara penjual unit dan si calo).
class PenjualanRepository {
  final Database db;

  PenjualanRepository(this.db);

  Future<PenjualanModel> jualMotor({
    required int motorId,
    required DateTime tanggalJual,
    required double hargaJual,
    required String penjual,
    int? periodeId,
  }) async {
    return db.transaction<PenjualanModel>((txn) async {
      final auditLog = AuditLogRepository(txn);
      final saldoRepo = SaldoRepository(txn);

      final motorResult =
          await txn.query('motor', where: 'id = ?', whereArgs: [motorId]);
      if (motorResult.isEmpty) {
        throw ArgumentError('Motor tidak ditemukan');
      }
      final motor = MotorModel.fromMap(motorResult.first);

      if (motor.isTerjual) {
        throw StateError('Motor ${motor.kodeMotor} sudah terjual sebelumnya.');
      }

      final modalMotor = motor.totalModal;
      final laba = hargaJual - modalMotor;

      // Aturan Calo: bonus_eligible = false, laba & status tetap normal.
      final bonusEligible = penjual != AppConstants.penjualCalo;

      final now = DateTime.now();
      final penjualan = PenjualanModel(
        motorId: motorId,
        tanggalJual: tanggalJual,
        hargaJual: hargaJual,
        modalMotor: modalMotor,
        laba: laba,
        penjual: penjual,
        bonusEligible: bonusEligible,
        periodeId: periodeId,
        createdAt: now,
      );

      final penjualanId = await txn.insert('penjualan', penjualan.toMap());
      final saved = PenjualanModel.fromMap({
        ...penjualan.toMap(),
        'id': penjualanId,
      });

      await auditLog.catatCreate(
        'penjualan',
        penjualanId,
        jsonEncode(saved.toMap()),
        keterangan: 'Jual ${motor.kodeMotor} oleh $penjual'
            '${bonusEligible ? "" : " (CALO - tidak dapat bonus)"}',
      );

      // Update status motor -> TERJUAL
      final motorLamaMap = motor.toMap();
      await txn.update(
        'motor',
        {
          'status': AppConstants.statusMotorTerjual,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [motorId],
      );
      await auditLog.catatUpdate(
        'motor',
        motorId,
        jsonEncode(motorLamaMap),
        jsonEncode({...motorLamaMap, 'status': AppConstants.statusMotorTerjual}),
        keterangan: 'Status motor -> TERJUAL',
      );

      // Catat pemasukan otomatis dari penjualan
      final pemasukan = PemasukanModel(
        tanggal: tanggalJual,
        kategori: 'Penjualan Motor',
        nominal: hargaJual,
        keterangan: 'Penjualan ${motor.kodeMotor} - ${motor.namaLengkap}',
        referensiId: penjualanId,
        periodeId: periodeId,
        createdAt: now,
      );
      final pemasukanId = await txn.insert('pemasukan', pemasukan.toMap());
      await auditLog.catatCreate(
        'pemasukan',
        pemasukanId,
        jsonEncode(pemasukan.toMap()),
      );

      // Tambah cash sejumlah harga jual
      await saldoRepo.mutasiCash(
        nominal: hargaJual,
        tipe: AppConstants.cashFlowMasuk,
        referensi: AppConstants.cashFlowRefPenjualan,
        referensiId: penjualanId,
        keterangan: 'Penjualan ${motor.kodeMotor} oleh $penjual',
        tanggal: tanggalJual,
      );

      return saved;
    });
  }

  Future<List<PenjualanModel>> getAll({int? periodeId}) async {
    final result = await db.query(
      'penjualan',
      where: periodeId != null ? 'periode_id = ?' : null,
      whereArgs: periodeId != null ? [periodeId] : null,
      orderBy: 'tanggal_jual DESC',
    );
    return result.map((e) => PenjualanModel.fromMap(e)).toList();
  }

  Future<PenjualanModel?> getByMotorId(int motorId) async {
    final result = await db.query(
      'penjualan',
      where: 'motor_id = ?',
      whereArgs: [motorId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return PenjualanModel.fromMap(result.first);
  }

  /// Rekap total penjualan per penjual dalam suatu periode.
  /// Dipakai untuk laporan "Penjualan per Orang".
  Future<Map<String, int>> getJumlahUnitPerPenjual(int periodeId) async {
    final result = await db.rawQuery('''
      SELECT penjual, COUNT(*) as jumlah
      FROM penjualan
      WHERE periode_id = ?
      GROUP BY penjual
    ''', [periodeId]);

    final map = <String, int>{};
    for (final row in result) {
      map[row['penjual'] as String] = row['jumlah'] as int;
    }
    return map;
  }
}
