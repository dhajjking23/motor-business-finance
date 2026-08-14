import 'package:equatable/equatable.dart';

class CashFlowModel extends Equatable {
  final int? id;
  final DateTime tanggal;
  final String tipe; // MASUK / KELUAR
  final double nominal;
  final String referensi; // kode referensi, lihat AppConstants.cashFlowRef*
  final int? referensiId;
  final String? keterangan;
  final double saldoSetelah;
  final DateTime createdAt;

  const CashFlowModel({
    this.id,
    required this.tanggal,
    required this.tipe,
    required this.nominal,
    required this.referensi,
    this.referensiId,
    this.keterangan,
    required this.saldoSetelah,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tanggal': tanggal.toIso8601String(),
      'tipe': tipe,
      'nominal': nominal,
      'referensi': referensi,
      'referensi_id': referensiId,
      'keterangan': keterangan,
      'saldo_setelah': saldoSetelah,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CashFlowModel.fromMap(Map<String, dynamic> map) {
    return CashFlowModel(
      id: map['id'] as int?,
      tanggal: DateTime.parse(map['tanggal'] as String),
      tipe: map['tipe'] as String,
      nominal: (map['nominal'] as num).toDouble(),
      referensi: map['referensi'] as String,
      referensiId: map['referensi_id'] as int?,
      keterangan: map['keterangan'] as String?,
      saldoSetelah: (map['saldo_setelah'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        tanggal,
        tipe,
        nominal,
        referensi,
        referensiId,
        keterangan,
        saldoSetelah,
        createdAt,
      ];
}
