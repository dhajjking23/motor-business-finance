import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../core/constants/app_constants.dart';
import '../models/periode_model.dart';
import 'audit_log_repository.dart';

class PeriodeRepository {
  final Database db;
  late final AuditLogRepository _auditLog;

  PeriodeRepository(this.db) {
    _auditLog = AuditLogRepository(db);
  }

  Future<PeriodeModel> buatPeriode({
    required String namaPeriode,
    required DateTime tanggalMulai,
    double modalAwal = 0,
  }) async {
    final aktif = await getPeriodeAktif();
    if (aktif != null) {
      throw StateError(
        'Masih ada periode aktif ("${aktif.namaPeriode}"). '
        'Tutup buku periode tersebut terlebih dahulu sebelum membuat periode baru.',
      );
    }

    final now = DateTime.now();
    final periode = PeriodeModel(
      namaPeriode: namaPeriode,
      tanggalMulai: tanggalMulai,
      status: AppConstants.statusPeriodeAktif,
      modalAwal: modalAwal,
      createdAt: now,
      updatedAt: now,
    );
    final id = await db.insert('periode', periode.toMap());
    final saved = periode.copyWith(id: id);
    await _auditLog.catatCreate('periode', id, jsonEncode(saved.toMap()));
    return saved;
  }

  Future<PeriodeModel?> getPeriodeAktif() async {
    final result = await db.query(
      'periode',
      where: 'status = ?',
      whereArgs: [AppConstants.statusPeriodeAktif],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return PeriodeModel.fromMap(result.first);
  }

  Future<PeriodeModel?> getById(int id) async {
    final result = await db.query('periode', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return PeriodeModel.fromMap(result.first);
  }

  Future<List<PeriodeModel>> getAll() async {
    final result = await db.query('periode', orderBy: 'tanggal_mulai DESC');
    return result.map((e) => PeriodeModel.fromMap(e)).toList();
  }

  /// Menutup buku periode. Tidak menghitung laba di sini — perhitungan
  /// & pembagian laba dilakukan oleh PembagianLabaService lalu hasilnya
  /// disimpan terpisah di tabel pembagian_laba.
  Future<PeriodeModel> tutupPeriode(int periodeId, {DateTime? tanggalSelesai}) async {
    final periode = await getById(periodeId);
    if (periode == null) throw ArgumentError('Periode tidak ditemukan');
    if (!periode.isAktif) {
      throw StateError('Periode ini sudah ditutup sebelumnya.');
    }

    final dataLama = jsonEncode(periode.toMap());
    final updated = periode.copyWith(
      status: AppConstants.statusPeriodeTutup,
      tanggalSelesai: tanggalSelesai ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await db.update('periode', updated.toMap(),
        where: 'id = ?', whereArgs: [periodeId]);
    await _auditLog.catatUpdate(
      'periode',
      periodeId,
      dataLama,
      jsonEncode(updated.toMap()),
      keterangan: 'Tutup buku periode',
    );
    return updated;
  }
}
