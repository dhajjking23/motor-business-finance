import 'package:equatable/equatable.dart';

class SaldoModel extends Equatable {
  final double cash;
  final double saldoBank;
  final double modalTotal;
  final DateTime updatedAt;

  const SaldoModel({
    required this.cash,
    required this.saldoBank,
    required this.modalTotal,
    required this.updatedAt,
  });

  double get totalKas => cash + saldoBank;

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'cash': cash,
      'saldo_bank': saldoBank,
      'modal_total': modalTotal,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SaldoModel.fromMap(Map<String, dynamic> map) {
    return SaldoModel(
      cash: (map['cash'] as num).toDouble(),
      saldoBank: (map['saldo_bank'] as num).toDouble(),
      modalTotal: (map['modal_total'] as num).toDouble(),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  SaldoModel copyWith({
    double? cash,
    double? saldoBank,
    double? modalTotal,
    DateTime? updatedAt,
  }) {
    return SaldoModel(
      cash: cash ?? this.cash,
      saldoBank: saldoBank ?? this.saldoBank,
      modalTotal: modalTotal ?? this.modalTotal,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [cash, saldoBank, modalTotal, updatedAt];
}
