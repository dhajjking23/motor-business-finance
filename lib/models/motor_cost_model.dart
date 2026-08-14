import 'package:equatable/equatable.dart';

class MotorCostModel extends Equatable {
  final int? id;
  final int motorId;
  final String kategori;
  final double nominal;
  final String? keterangan;
  final DateTime tanggal;
  final DateTime createdAt;

  const MotorCostModel({
    this.id,
    required this.motorId,
    required this.kategori,
    required this.nominal,
    this.keterangan,
    required this.tanggal,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'motor_id': motorId,
      'kategori': kategori,
      'nominal': nominal,
      'keterangan': keterangan,
      'tanggal': tanggal.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MotorCostModel.fromMap(Map<String, dynamic> map) {
    return MotorCostModel(
      id: map['id'] as int?,
      motorId: map['motor_id'] as int,
      kategori: map['kategori'] as String,
      nominal: (map['nominal'] as num).toDouble(),
      keterangan: map['keterangan'] as String?,
      tanggal: DateTime.parse(map['tanggal'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  MotorCostModel copyWith({
    int? id,
    int? motorId,
    String? kategori,
    double? nominal,
    String? keterangan,
    DateTime? tanggal,
    DateTime? createdAt,
  }) {
    return MotorCostModel(
      id: id ?? this.id,
      motorId: motorId ?? this.motorId,
      kategori: kategori ?? this.kategori,
      nominal: nominal ?? this.nominal,
      keterangan: keterangan ?? this.keterangan,
      tanggal: tanggal ?? this.tanggal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, motorId, kategori, nominal, keterangan, tanggal, createdAt];
}
