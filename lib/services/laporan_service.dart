import 'package:sqflite/sqflite.dart';
import '../repositories/motor_repository.dart';
import '../repositories/penjualan_repository.dart';
import '../repositories/pengeluaran_repository.dart';
import '../repositories/pemasukan_repository.dart';
import '../models/penjualan_model.dart';
import '../models/motor_model.dart';

class LabaPerMotor {
  final MotorModel motor;
  final PenjualanModel penjualan;
  double get laba => penjualan.laba;
  LabaPerMotor(this.motor, this.penjualan);
}

class LaporanPeriodeData {
  final List<LabaPerMotor> labaPerMotor;
  final Map<String, double> pengeluaranPerKategori;
  final Map<String, int> penjualanPerOrang;
  final double totalLabaMotor;
  final double totalPengeluaran;
  final double totalPemasukan;

  LaporanPeriodeData({
    required this.labaPerMotor,
    required this.pengeluaranPerKategori,
    required this.penjualanPerOrang,
    required this.totalLabaMotor,
    required this.totalPengeluaran,
    required this.totalPemasukan,
  });
}

/// Service agregasi untuk halaman Laporan. Menggabungkan data dari
/// beberapa repository menjadi struktur siap-tampil dan siap-export.
class LaporanService {
  final Database db;
  late final MotorRepository _motorRepo;
  late final PenjualanRepository _penjualanRepo;
  late final PengeluaranRepository _pengeluaranRepo;
  late final PemasukanRepository _pemasukanRepo;

  LaporanService(this.db) {
    _motorRepo = MotorRepository(db);
    _penjualanRepo = PenjualanRepository(db);
    _pengeluaranRepo = PengeluaranRepository(db);
    _pemasukanRepo = PemasukanRepository(db);
  }

  Future<LaporanPeriodeData> getLaporanPeriode(int periodeId) async {
    final semuaPenjualan = await _penjualanRepo.getAll(periodeId: periodeId);

    final labaPerMotor = <LabaPerMotor>[];
    for (final p in semuaPenjualan) {
      final motor = await _motorRepo.getById(p.motorId);
      if (motor != null) {
        labaPerMotor.add(LabaPerMotor(motor, p));
      }
    }

    final semuaPengeluaran =
        await _pengeluaranRepo.getAll(periodeId: periodeId);
    final pengeluaranPerKategori = <String, double>{};
    for (final p in semuaPengeluaran) {
      pengeluaranPerKategori[p.kategori] =
          (pengeluaranPerKategori[p.kategori] ?? 0) + p.nominal;
    }

    final penjualanPerOrang =
        await _penjualanRepo.getJumlahUnitPerPenjual(periodeId);

    final semuaPemasukan = await _pemasukanRepo.getAll(periodeId: periodeId);
    final totalPemasukan =
        semuaPemasukan.fold<double>(0, (sum, p) => sum + p.nominal);
    final totalPengeluaran =
        semuaPengeluaran.fold<double>(0, (sum, p) => sum + p.nominal);
    final totalLabaMotor =
        semuaPenjualan.fold<double>(0, (sum, p) => sum + p.laba);

    return LaporanPeriodeData(
      labaPerMotor: labaPerMotor,
      pengeluaranPerKategori: pengeluaranPerKategori,
      penjualanPerOrang: penjualanPerOrang,
      totalLabaMotor: totalLabaMotor,
      totalPengeluaran: totalPengeluaran,
      totalPemasukan: totalPemasukan,
    );
  }
}
