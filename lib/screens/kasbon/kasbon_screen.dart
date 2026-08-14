import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_formatter.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common_widgets.dart';

class KasbonScreen extends ConsumerWidget {
  const KasbonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kasbonAsync = ref.watch(daftarKasbonProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kasbon Karyawan')),
      body: kasbonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(message: 'Belum ada data kasbon');
          }
          final belumLunas = list
              .where((k) => k.status == AppConstants.statusKasbonBelumLunas)
              .fold<double>(0, (s, k) => s + k.jumlah);

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Piutang Belum Lunas',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      AppFormatter.rupiah(belumLunas),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.danger,
                          fontSize: 16),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final k = list[i];
                    final lunas = k.isLunas;
                    return Card(
                      child: ListTile(
                        title: Text(k.namaKaryawan,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(AppFormatter.tanggal(k.tanggal)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppFormatter.rupiah(k.jumlah),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            if (lunas)
                              const Text('Lunas',
                                  style: TextStyle(
                                      color: AppTheme.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700))
                            else
                              GestureDetector(
                                onTap: () async {
                                  final repo = await ref
                                      .read(kasbonRepositoryProvider.future);
                                  await repo.bayarKasbon(k.id!);
                                  refreshSemuaData(ref);
                                },
                                child: const Text('Tandai Lunas',
                                    style: TextStyle(
                                        color: AppTheme.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        decoration:
                                            TextDecoration.underline)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTambahDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Kasbon Baru'),
      ),
    );
  }

  void _showTambahDialog(BuildContext context, WidgetRef ref) {
    final jumlahController = TextEditingController();
    final keteranganController = TextEditingController();
    String namaKaryawan = AppConstants.karyawanDefault.first;
    DateTime tanggal = DateTime.now();
    bool loading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Kasbon Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: namaKaryawan,
                      decoration: const InputDecoration(labelText: 'Karyawan'),
                      items: AppConstants.karyawanDefault
                          .map((k) =>
                              DropdownMenuItem(value: k, child: Text(k)))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => namaKaryawan = v!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: jumlahController,
                      decoration: const InputDecoration(
                          labelText: 'Jumlah', prefixText: 'Rp '),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: keteranganController,
                      decoration: const InputDecoration(
                          labelText: 'Keterangan (opsional)'),
                    ),
                  ],
                ),
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
                          final jumlah = double.tryParse(
                              jumlahController.text.replaceAll('.', ''));
                          if (jumlah == null || jumlah <= 0) return;
                          setDialogState(() => loading = true);
                          try {
                            final repo = await ref
                                .read(kasbonRepositoryProvider.future);
                            await repo.ambilKasbon(
                              namaKaryawan: namaKaryawan,
                              tanggal: tanggal,
                              jumlah: jumlah,
                              keterangan: keteranganController.text.trim().isEmpty
                                  ? null
                                  : keteranganController.text.trim(),
                            );
                            refreshSemuaData(ref);
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
