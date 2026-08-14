import 'package:equatable/equatable.dart';
import '../core/constants/app_constants.dart';

class KasbonModel extends Equatable {
  final int? id;
  final String namaKaryawan;
  final DateTime tanggal;
  final double jumlah;
  final String status;
  final DateTime? tanggalLunas;
  final String? keterangan;
  final DateTime createdAt;
  final DateTime updatedAt;

  const KasbonModel({
    this.id,
    required this.namaKaryawan,
    required this.tanggal,
    required this.jumlah,
    this.status = AppConstants.statusKasbonBelumLunas,
    this.tanggalLunas,
    this.keterangan,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLunas => status == AppConstants.statusKasbonLunas;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama_karyawan': namaKaryawan,
      'tanggal': tanggal.toIso8601String(),
      'jumlah': jumlah,
      'status': status,
      'tanggal_lunas': tanggalLunas?.toIso8601String(),
      'keterangan': keterangan,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory KasbonModel.fromMap(Map<String, dynamic> map) {
    return KasbonModel(
      id: map['id'] as int?,
      namaKaryawan: map['nama_karyawan'] as String,
      tanggal: DateTime.parse(map['tanggal'] as String),
      jumlah: (map['jumlah'] as num).toDouble(),
      status: map['status'] as String,
      tanggalLunas: map['tanggal_lunas'] != null
          ? DateTime.parse(map['tanggal_lunas'] as String)
          : null,
      keterangan: map['keterangan'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  KasbonModel copyWith({
    int? id,
    String? namaKaryawan,
    DateTime? tanggal,
    double? jumlah,
    String? status,
    DateTime? tanggalLunas,
    String? keterangan,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KasbonModel(
      id: id ?? this.id,
      namaKaryawan: namaKaryawan ?? this.namaKaryawan,
      tanggal: tanggal ?? this.tanggal,
      jumlah: jumlah ?? this.jumlah,
      status: status ?? this.status,
      tanggalLunas: tanggalLunas ?? this.tanggalLunas,
      keterangan: keterangan ?? this.keterangan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        namaKaryawan,
        tanggal,
        jumlah,
        status,
        tanggalLunas,
        keterangan,
        createdAt,
        updatedAt,
      ];
}
