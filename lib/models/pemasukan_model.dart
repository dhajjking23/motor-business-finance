import 'package:equatable/equatable.dart';

class PemasukanModel extends Equatable {
  final int? id;
  final DateTime tanggal;
  final String kategori;
  final double nominal;
  final String? keterangan;
  final int? referensiId;
  final int? periodeId;
  final DateTime createdAt;

  const PemasukanModel({
    this.id,
    required this.tanggal,
    required this.kategori,
    required this.nominal,
    this.keterangan,
    this.referensiId,
    this.periodeId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tanggal': tanggal.toIso8601String(),
      'kategori': kategori,
      'nominal': nominal,
      'keterangan': keterangan,
      'referensi_id': referensiId,
      'periode_id': periodeId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PemasukanModel.fromMap(Map<String, dynamic> map) {
    return PemasukanModel(
      id: map['id'] as int?,
      tanggal: DateTime.parse(map['tanggal'] as String),
      kategori: map['kategori'] as String,
      nominal: (map['nominal'] as num).toDouble(),
      keterangan: map['keterangan'] as String?,
      referensiId: map['referensi_id'] as int?,
      periodeId: map['periode_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        tanggal,
        kategori,
        nominal,
        keterangan,
        referensiId,
        periodeId,
        createdAt,
      ];
}
