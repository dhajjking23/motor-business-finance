import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../core/constants/app_constants.dart';
import '../models/motor_model.dart';
import '../models/motor_cost_model.dart';
import 'audit_log_repository.dart';
import 'saldo_repository.dart';

/// Repository motor. Menangani logika pembelian unit (harga beli + biaya
/// = total modal), penambahan biaya susulan, dan query stok/histori.
///
/// SEMUA operasi yang mengubah kas (pembelian & tambah biaya) dibungkus
/// dalam database transaction agar konsisten: motor, motor_cost, saldo,
/// dan cash_flow harus berhasil bersamaan atau gagal bersamaan.
class MotorRepository {
  final Database db;

  MotorRepository(this.db);

  Future<String> _generateKodeMotor(DatabaseExecutor txn) async {
    final result = await txn.rawQuery('SELECT COUNT(*) as cnt FROM motor');
    final count = Sqflite.firstIntValue(result) ?? 0;
    final nomor = (count + 1).toString().padLeft(4, '0');
    return 'MTR-$nomor';
  }

  /// Menambahkan motor baru ke stok.
  ///
  /// [biayaAwal] adalah daftar biaya (kategori & nominal) yang langsung
  /// dikeluarkan saat pembelian, misal: Transportasi, Bensin, Service, dll.
  /// Total modal = hargaBeli + total semua biayaAwal.
  /// Cash otomatis berkurang sejumlah total modal tersebut.
  Future<MotorModel> tambahMotor({
    required String merk,
    required String tipe,
    int? tahun,
    String? warna,
    String? platNomor,
    required DateTime tanggalMasuk,
    required double hargaBeli,
    int? periodeId,
    List<MotorCostModel> biayaAwal = const [],
  }) async {
    return db.transaction<MotorModel>((txn) async {
      final auditLog = AuditLogRepository(txn);
      final saldoRepo = SaldoRepository(txn);

      final kodeMotor = await _generateKodeMotor(txn);
      final now = DateTime.now();

      final totalBiaya =
          biayaAwal.fold<double>(0, (sum, c) => sum + c.nominal);
      final totalModal = hargaBeli + totalBiaya;

      final motor = MotorModel(
        kodeMotor: kodeMotor,
        merk: merk,
        tipe: tipe,
        tahun: tahun,
        warna: warna,
        platNomor: platNomor,
        tanggalMasuk: tanggalMasuk,
        hargaBeli: hargaBeli,
        totalModal: totalModal,
        status: AppConstants.statusMotorTersedia,
        periodeId: periodeId,
        createdAt: now,
        updatedAt: now,
      );

      final motorId = await txn.insert('motor', motor.toMap());
      final savedMotor = motor.copyWith(id: motorId);

      await auditLog.catatCreate(
        'motor',
        motorId,
        jsonEncode(savedMotor.toMap()),
        keterangan: 'Pembelian unit $kodeMotor',
      );

      // Simpan setiap biaya awal ke motor_cost
      for (final biaya in biayaAwal) {
        final costToSave = biaya.copyWith(motorId: motorId, createdAt: now);
        final costId = await txn.insert('motor_cost', costToSave.toMap());
        await auditLog.catatCreate(
          'motor_cost',
          costId,
          jsonEncode(costToSave.toMap()),
        );
      }

      // Kurangi cash sejumlah total modal (harga beli + semua biaya)
      await saldoRepo.mutasiCash(
        nominal: totalModal,
        tipe: AppConstants.cashFlowKeluar,
        referensi: AppConstants.cashFlowRefMotorBeli,
        referensiId: motorId,
        keterangan: 'Pembelian unit $kodeMotor ($merk $tipe)',
        tanggal: tanggalMasuk,
      );

      return savedMotor;
    });
  }

  /// Menambahkan biaya susulan ke motor yang sudah ada (misal service
  /// tambahan setelah unit masuk stok). Otomatis update total_modal
  /// motor dan mengurangi cash.
  Future<MotorModel> tambahBiaya({
    required int motorId,
    required String kategori,
    required double nominal,
    String? keterangan,
    DateTime? tanggal,
  }) async {
    return db.transaction<MotorModel>((txn) async {
      final auditLog = AuditLogRepository(txn);
      final saldoRepo = SaldoRepository(txn);

      final motorResult =
          await txn.query('motor', where: 'id = ?', whereArgs: [motorId]);
      if (motorResult.isEmpty) {
        throw ArgumentError('Motor tidak ditemukan');
      }
      final motorLama = MotorModel.fromMap(motorResult.first);

      final now = DateTime.now();
      final cost = MotorCostModel(
        motorId: motorId,
        kategori: kategori,
        nominal: nominal,
        keterangan: keterangan,
        tanggal: tanggal ?? now,
        createdAt: now,
      );
      final costId = await txn.insert('motor_cost', cost.toMap());
      await auditLog.catatCreate(
          'motor_cost', costId, jsonEncode(cost.toMap()));

      final motorBaru = motorLama.copyWith(
        totalModal: motorLama.totalModal + nominal,
        updatedAt: now,
      );
      await txn.update('motor', motorBaru.toMap(),
          where: 'id = ?', whereArgs: [motorId]);
      await auditLog.catatUpdate(
        'motor',
        motorId,
        jsonEncode(motorLama.toMap()),
        jsonEncode(motorBaru.toMap()),
        keterangan: 'Tambah biaya $kategori: Rp$nominal',
      );

      await saldoRepo.mutasiCash(
        nominal: nominal,
        tipe: AppConstants.cashFlowKeluar,
        referensi: AppConstants.cashFlowRefMotorCost,
        referensiId: motorId,
        keterangan: '$kategori - ${motorBaru.kodeMotor}',
        tanggal: tanggal,
      );

      return motorBaru;
    });
  }

  Future<MotorModel?> getById(int id) async {
    final result = await db.query('motor', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return MotorModel.fromMap(result.first);
  }

  Future<List<MotorModel>> getAll({String? status, String? searchQuery}) async {
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (status != null) {
      whereClauses.add('status = ?');
      whereArgs.add(status);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClauses.add(
          '(kode_motor LIKE ? OR merk LIKE ? OR tipe LIKE ? OR plat_nomor LIKE ?)');
      final like = '%$searchQuery%';
      whereArgs.addAll([like, like, like, like]);
    }

    final result = await db.query(
      'motor',
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'tanggal_masuk DESC',
    );
    return result.map((e) => MotorModel.fromMap(e)).toList();
  }

  Future<List<MotorModel>> getStokTersedia() =>
      getAll(status: AppConstants.statusMotorTersedia);

  Future<List<MotorCostModel>> getRiwayatBiaya(int motorId) async {
    final result = await db.query(
      'motor_cost',
      where: 'motor_id = ?',
      whereArgs: [motorId],
      orderBy: 'tanggal ASC',
    );
    return result.map((e) => MotorCostModel.fromMap(e)).toList();
  }

  /// Total nilai aset stok motor yang belum terjual (dipakai Dashboard).
  Future<double> getTotalNilaiStok() async {
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(total_modal), 0) as total FROM motor WHERE status = ?',
      [AppConstants.statusMotorTersedia],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<MotorModel> updateMotor(MotorModel motor) async {
    final motorLama = await getById(motor.id!);
    final updated = motor.copyWith(updatedAt: DateTime.now());
    await db.update('motor', updated.toMap(),
        where: 'id = ?', whereArgs: [motor.id]);
    final auditLog = AuditLogRepository(db);
    await auditLog.catatUpdate(
      'motor',
      motor.id!,
      jsonEncode(motorLama?.toMap()),
      jsonEncode(updated.toMap()),
    );
    return updated;
  }

  /// Update status motor jadi TERJUAL. Dipanggil oleh PenjualanRepository
  /// di dalam transaction yang sama, bukan dipanggil langsung dari UI.
  Future<void> tandaiTerjual(DatabaseExecutor txn, int motorId) async {
    await txn.update(
      'motor',
      {
        'status': AppConstants.statusMotorTerjual,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [motorId],
    );
  }
}
