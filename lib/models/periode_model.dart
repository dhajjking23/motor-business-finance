import 'package:equatable/equatable.dart';
import '../core/constants/app_constants.dart';

class PeriodeModel extends Equatable {
  final int? id;
  final String namaPeriode;
  final DateTime tanggalMulai;
  final DateTime? tanggalSelesai;
  final String status;
  final double modalAwal;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PeriodeModel({
    this.id,
    required this.namaPeriode,
    required this.tanggalMulai,
    this.tanggalSelesai,
    this.status = AppConstants.statusPeriodeAktif,
    this.modalAwal = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAktif => status == AppConstants.statusPeriodeAktif;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama_periode': namaPeriode,
      'tanggal_mulai': tanggalMulai.toIso8601String(),
      'tanggal_selesai': tanggalSelesai?.toIso8601String(),
      'status': status,
      'modal_awal': modalAwal,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PeriodeModel.fromMap(Map<String, dynamic> map) {
    return PeriodeModel(
      id: map['id'] as int?,
      namaPeriode: map['nama_periode'] as String,
      tanggalMulai: DateTime.parse(map['tanggal_mulai'] as String),
      tanggalSelesai: map['tanggal_selesai'] != null
          ? DateTime.parse(map['tanggal_selesai'] as String)
          : null,
      status: map['status'] as String,
      modalAwal: (map['modal_awal'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  PeriodeModel copyWith({
    int? id,
    String? namaPeriode,
    DateTime? tanggalMulai,
    DateTime? tanggalSelesai,
    String? status,
    double? modalAwal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PeriodeModel(
      id: id ?? this.id,
      namaPeriode: namaPeriode ?? this.namaPeriode,
      tanggalMulai: tanggalMulai ?? this.tanggalMulai,
      tanggalSelesai: tanggalSelesai ?? this.tanggalSelesai,
      status: status ?? this.status,
      modalAwal: modalAwal ?? this.modalAwal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        namaPeriode,
        tanggalMulai,
        tanggalSelesai,
        status,
        modalAwal,
        createdAt,
        updatedAt,
      ];
}
