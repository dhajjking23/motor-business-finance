import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_formatter.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common_widgets.dart';

class MotorDetailScreen extends ConsumerWidget {
  final int motorId;

  const MotorDetailScreen({super.key, required this.motorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motorListAsync = ref.watch(daftarMotorProvider(null));
    final riwayatAsync = ref.watch(riwayatBiayaMotorProvider(motorId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Motor')),
      body: motorListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (motorList) {
          final motor = motorList.firstWhere((m) => m.id == motorId);
          final isTerjual = motor.isTerjual;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          motor.kodeMotor,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isTerjual ? 'Terjual' : 'Tersedia',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      motor.namaLengkap,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (motor.platNomor != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          motor.platNomor!,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _DetailRow(label: 'Harga Beli', value: AppFormatter.rupiah(motor.hargaBeli)),
                      const Divider(height: 20),
                      _DetailRow(
                        label: 'TOTAL MODAL',
                        value: AppFormatter.rupiah(motor.totalModal),
                        bold: true,
                        valueColor: AppTheme.primary,
                      ),
                      const Divider(height: 20),
                      _DetailRow(
                          label: 'Tanggal Masuk',
                          value: AppFormatter.tanggal(motor.tanggalMasuk)),
                      if (motor.warna != null) ...[
                        const Divider(height: 20),
                        _DetailRow(label: 'Warna', value: motor.warna!),
                      ],
                      if (motor.tahun != null) ...[
                        const Divider(height: 20),
                        _DetailRow(
                            label: 'Tahun', value: motor.tahun.toString()),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SectionTitle(title: 'Riwayat Biaya'),
              riwayatAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Error: $e'),
                data: (biayaList) {
                  if (biayaList.isEmpty) {
                    return const EmptyState(message: 'Belum ada biaya tambahan');
                  }
                  return Column(
                    children: biayaList.map((b) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(b.kategori,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: b.keterangan != null
                              ? Text(b.keterangan!)
                              : Text(AppFormatter.tanggal(b.tanggal)),
                          trailing: Text(
                            AppFormatter.rupiah(b.nominal),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              if (!isTerjual)
                ElevatedButton.icon(
                  onPressed: () => _showTambahBiayaDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Biaya Susulan'),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showTambahBiayaDialog(BuildContext context, WidgetRef ref) {
    final nominalController = TextEditingController();
    final keteranganController = TextEditingController();
    String kategori = AppConstants.kategoriMotorCost[1];
    bool loading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Biaya'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: kategori,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: AppConstants.kategoriMotorCost
                        .where((k) => k != 'Pembelian Unit')
                        .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => kategori = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nominalController,
                    decoration: const InputDecoration(
                        labelText: 'Nominal', prefixText: 'Rp '),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: keteranganController,
                    decoration:
                        const InputDecoration(labelText: 'Keterangan (opsional)'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          final nominal = double.tryParse(
                              nominalController.text.replaceAll('.', ''));
                          if (nominal == null || nominal <= 0) return;

                          setDialogState(() => loading = true);
                          try {
                            final repo =
                                await ref.read(motorRepositoryProvider.future);
                            await repo.tambahBiaya(
                              motorId: motorId,
                              kategori: kategori,
                              nominal: nominal,
                              keterangan: keteranganController.text.trim().isEmpty
                                  ? null
                                  : keteranganController.text.trim(),
                            );
                            refreshSemuaData(ref);
                            ref.invalidate(riwayatBiayaMotorProvider(motorId));
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          } catch (e) {
                            setDialogState(() => loading = false);
                          }
                        },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
