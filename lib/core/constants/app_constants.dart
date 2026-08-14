/// Konstanta global aplikasi Garasi Abah Bontot
/// Semua nilai default, kategori, dan aturan bisnis didefinisikan di sini
/// agar tidak hardcode tersebar di banyak file.
class AppConstants {
  AppConstants._();

  static const String appName = 'Garasi Abah Bontot';
  static const String dbName = 'garasi_abah_bontot.db';
  static const int dbVersion = 1;

  // ==========================================================
  // KARYAWAN DEFAULT (internal / berhak dapat pembagian laba & bonus)
  // ==========================================================
  static const List<String> karyawanDefault = [
    'Abah',
    'Iki',
    'Andri',
    'Ilham',
  ];

  /// Daftar penjual yang muncul di form penjualan (internal + calo)
  static const List<String> daftarPenjual = [
    'Abah',
    'Iki',
    'Andri',
    'Ilham',
    'Calo',
  ];

  static const String penjualCalo = 'Calo';

  // ==========================================================
  // KATEGORI BIAYA MOTOR (motor_cost)
  // ==========================================================
  static const List<String> kategoriMotorCost = [
    'Pembelian Unit',
    'Transportasi',
    'Bensin',
    'Makan COD',
    'Rokok COD',
    'Service',
    'Sparepart',
    'Gajih Service',
    'Finishing',
    'Custom',
  ];

  // ==========================================================
  // KATEGORI PEMASUKAN
  // ==========================================================
  static const List<String> kategoriPemasukan = [
    'Tambah Modal',
    'Penjualan Motor',
    'Custom',
  ];

  // ==========================================================
  // KATEGORI PENGELUARAN
  // ==========================================================
  static const List<String> kategoriPengeluaran = [
    'Kasbon',
    'Pengeluaran Lain',
  ];

  // ==========================================================
  // STATUS
  // ==========================================================
  static const String statusMotorTersedia = 'TERSEDIA';
  static const String statusMotorTerjual = 'TERJUAL';

  static const String statusPeriodeAktif = 'AKTIF';
  static const String statusPeriodeTutup = 'TUTUP';

  static const String statusKasbonBelumLunas = 'BELUM_LUNAS';
  static const String statusKasbonLunas = 'LUNAS';

  // ==========================================================
  // CASH FLOW TIPE
  // ==========================================================
  static const String cashFlowMasuk = 'MASUK';
  static const String cashFlowKeluar = 'KELUAR';

  static const String cashFlowRefMotorBeli = 'PEMBELIAN_MOTOR';
  static const String cashFlowRefMotorCost = 'BIAYA_MOTOR';
  static const String cashFlowRefPenjualan = 'PENJUALAN_MOTOR';
  static const String cashFlowRefPemasukan = 'PEMASUKAN';
  static const String cashFlowRefPengeluaran = 'PENGELUARAN';
  static const String cashFlowRefKasbonAmbil = 'KASBON_AMBIL';
  static const String cashFlowRefKasbonBayar = 'KASBON_BAYAR';

  // ==========================================================
  // ATURAN PEMBAGIAN LABA (persentase dari laba bersih periode)
  // Total harus 100%: 25 + 27.5 + 22.5 + 15 + 10 = 100
  // ==========================================================
  static const double persenAbah = 0.25;
  static const double persenIki = 0.275;
  static const double persenAndri = 0.225;
  static const double persenIlham = 0.15;
  static const double persenHadiahPenjualan = 0.10;

  static const Map<String, double> pembagianLabaUtama = {
    'Abah': persenAbah,
    'Iki': persenIki,
    'Andri': persenAndri,
    'Ilham': persenIlham,
  };

  /// Penjual internal yang berhak atas hadiah penjualan (bonus 10%).
  /// Calo TIDAK termasuk.
  static const List<String> penjualInternalBerhakBonus = [
    'Abah',
    'Iki',
    'Andri',
    'Ilham',
  ];

  // ==========================================================
  // AUDIT LOG ACTION TYPE
  // ==========================================================
  static const String auditCreate = 'CREATE';
  static const String auditUpdate = 'UPDATE';
  static const String auditDelete = 'DELETE';
}
