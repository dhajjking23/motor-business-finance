import 'package:sqflite/sqflite.dart';
import '../core/constants/app_constants.dart';
import '../models/saldo_model.dart';
import '../models/cash_flow_model.dart';

/// Mengelola saldo cash & bank (singleton row) beserta histori cash_flow.
/// Semua transaksi yang mempengaruhi kas HARUS lewat repository ini supaya
/// saldo selalu konsisten dan setiap mutasi tercatat di cash_flow.
class SaldoRepository {
  final DatabaseExecutor db;

  SaldoRepository(this.db);

  Future<SaldoModel> getSaldo() async {
    final result = await db.query('saldo', where: 'id = 1', limit: 1);
    if (result.isEmpty) {
      // Fallback jika baris singleton belum ada (seharusnya sudah di-seed)
      final now = DateTime.now();
      final saldo = SaldoModel(
        cash: 0,
        saldoBank: 0,
        modalTotal: 0,
        updatedAt: now,
      );
      await db.insert('saldo', saldo.toMap());
      return saldo;
    }
    return SaldoModel.fromMap(result.first);
  }

  Future<void> _updateSaldo(SaldoModel saldo) async {
    await db.update(
      'saldo',
      saldo.toMap(),
      where: 'id = 1',
    );
  }

  /// Menambah/mengurangi cash, mencatat cash_flow, dan mengembalikan
  /// saldo terbaru. `nominal` boleh negatif untuk pengurangan.
  Future<SaldoModel> mutasiCash({
    required double nominal,
    required String tipe, // MASUK / KELUAR
    required String referensi,
    int? referensiId,
    String? keterangan,
    DateTime? tanggal,
  }) async {
    final saldoSekarang = await getSaldo();
    final delta = tipe == AppConstants.cashFlowMasuk ? nominal : -nominal;
    final saldoBaru = saldoSekarang.copyWith(
      cash: saldoSekarang.cash + delta,
      updatedAt: DateTime.now(),
    );
    await _updateSaldo(saldoBaru);

    final cashFlow = CashFlowModel(
      tanggal: tanggal ?? DateTime.now(),
      tipe: tipe,
      nominal: nominal,
      referensi: referensi,
      referensiId: referensiId,
      keterangan: keterangan,
      saldoSetelah: saldoBaru.cash,
      createdAt: DateTime.now(),
    );
    await db.insert('cash_flow', cashFlow.toMap());

    return saldoBaru;
  }

  Future<SaldoModel> tambahModal(double nominal, {String? keterangan}) async {
    final saldoSekarang = await getSaldo();
    final saldoBaru = saldoSekarang.copyWith(
      modalTotal: saldoSekarang.modalTotal + nominal,
      updatedAt: DateTime.now(),
    );
    await _updateSaldo(saldoBaru);
    return mutasiCash(
      nominal: nominal,
      tipe: AppConstants.cashFlowMasuk,
      referensi: AppConstants.cashFlowRefPemasukan,
      keterangan: keterangan ?? 'Tambah Modal',
    );
  }

  Future<SaldoModel> updateSaldoBank(double saldoBankBaru) async {
    final saldoSekarang = await getSaldo();
    final saldoBaru = saldoSekarang.copyWith(
      saldoBank: saldoBankBaru,
      updatedAt: DateTime.now(),
    );
    await _updateSaldo(saldoBaru);
    return saldoBaru;
  }

  Future<List<CashFlowModel>> getHistoriCashFlow(
      {DateTime? dari, DateTime? sampai}) async {
    String? where;
    List<Object?>? args;
    if (dari != null && sampai != null) {
      where = 'tanggal BETWEEN ? AND ?';
      args = [dari.toIso8601String(), sampai.toIso8601String()];
    }
    final result = await db.query(
      'cash_flow',
      where: where,
      whereArgs: args,
      orderBy: 'tanggal DESC, id DESC',
    );
    return result.map((e) => CashFlowModel.fromMap(e)).toList();
  }
}
