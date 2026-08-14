import 'package:equatable/equatable.dart';

class PenjualanModel extends Equatable {
  final int? id;
  final int motorId;
  final DateTime tanggalJual;
  final double hargaJual;
  final double modalMotor;
  final double laba;
  final String penjual;
  final bool bonusEligible;
  final int? periodeId;
  final DateTime createdAt;

  const PenjualanModel({
    this.id,
    required this.motorId,
    required this.tanggalJual,
    required this.hargaJual,
    required this.modalMotor,
    required this.laba,
    required this.penjual,
    this.bonusEligible = true,
    this.periodeId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'motor_id': motorId,
      'tanggal_jual': tanggalJual.toIso8601String(),
      'harga_jual': hargaJual,
      'modal_motor': modalMotor,
      'laba': laba,
      'penjual': penjual,
      'bonus_eligible': bonusEligible ? 1 : 0,
      'periode_id': periodeId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PenjualanModel.fromMap(Map<String, dynamic> map) {
    return PenjualanModel(
      id: map['id'] as int?,
      motorId: map['motor_id'] as int,
      tanggalJual: DateTime.parse(map['tanggal_jual'] as String),
      hargaJual: (map['harga_jual'] as num).toDouble(),
      modalMotor: (map['modal_motor'] as num).toDouble(),
      laba: (map['laba'] as num).toDouble(),
      penjual: map['penjual'] as String,
      bonusEligible: (map['bonus_eligible'] as int) == 1,
      periodeId: map['periode_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        motorId,
        tanggalJual,
        hargaJual,
        modalMotor,
        laba,
        penjual,
        bonusEligible,
        periodeId,
        createdAt,
      ];
}
