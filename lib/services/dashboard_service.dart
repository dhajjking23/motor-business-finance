import 'package:sqflite/sqflite.dart';
import '../repositories/motor_repository.dart';
import '../repositories/saldo_repository.dart';
import '../repositories/kasbon_repository.dart';
import '../repositories/penjualan_repository.dart';
import '../repositories/periode_repository.dart';
import '../models/saldo_model.dart';

/// Ringkasan seluruh angka penting yang ditampilkan di layar Dashboard.
class DashboardSummary {
  final double modal;
  final double cash;
  final double saldoBank;
  final double nilaiStokMotor;
  final double piutangKasbon;
  final double totalAset;
  final double totalPenjualanPeriodeAktif;
  final double totalLabaPeriodeAktif;
  final int jumlahUnitTersedia;
  final int jumlahUnitTerjualPeriodeAktif;
  final String? namaPeriodeAktif;

  DashboardSummary({
    required this.modal,
    required this.cash,
    required this.saldoBank,
    required this.nilaiStokMotor,
    required this.piutangKasbon,
    required this.totalAset,
    required this.totalPenjualanPeriodeAktif,
    required this.totalLabaPeriodeAktif,
    required this.jumlahUnitTersedia,
    required this.jumlahUnitTerjualPeriodeAktif,
    required this.namaPeriodeAktif,
  });
}

class DashboardService {
  final Database db;
  late final MotorRepository _motorRepo;
  late final SaldoRepository _saldoRepo;
  late final KasbonRepository _kasbonRepo;
  late final PenjualanRepository _penjualanRepo;
  late final PeriodeRepository _periodeRepo;

  DashboardService(this.db) {
    _motorRepo = MotorRepository(db);
    _saldoRepo = SaldoRepository(db);
    _kasbonRepo = KasbonRepository(db);
    _penjualanRepo = PenjualanRepository(db);
    _periodeRepo = PeriodeRepository(db);
  }

  Future<DashboardSummary> getSummary() async {
    final SaldoModel saldo = await _saldoRepo.getSaldo();
    final nilaiStok = await _motorRepo.getTotalNilaiStok();
    final piutangKasbon = await _kasbonRepo.getTotalPiutangBelumLunas();
    final stokTersedia = await _motorRepo.getStokTersedia();
    final periodeAktif = await _periodeRepo.getPeriodeAktif();

    double totalPenjualan = 0;
    double totalLaba = 0;
    int jumlahTerjual = 0;

    if (periodeAktif != null) {
      final penjualanPeriode =
          await _penjualanRepo.getAll(periodeId: periodeAktif.id);
      totalPenjualan =
          penjualanPeriode.fold<double>(0, (sum, p) => sum + p.hargaJual);
      totalLaba = penjualanPeriode.fold<double>(0, (sum, p) => sum + p.laba);
      jumlahTerjual = penjualanPeriode.length;
    }

    final totalAset =
        saldo.cash + saldo.saldoBank + nilaiStok + piutangKasbon;

    return DashboardSummary(
      modal: saldo.modalTotal,
      cash: saldo.cash,
      saldoBank: saldo.saldoBank,
      nilaiStokMotor: nilaiStok,
      piutangKasbon: piutangKasbon,
      totalAset: totalAset,
      totalPenjualanPeriodeAktif: totalPenjualan,
      totalLabaPeriodeAktif: totalLaba,
      jumlahUnitTersedia: stokTersedia.length,
      jumlahUnitTerjualPeriodeAktif: jumlahTerjual,
      namaPeriodeAktif: periodeAktif?.namaPeriode,
    );
  }
}
