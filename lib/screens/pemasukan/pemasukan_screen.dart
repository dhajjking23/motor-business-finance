import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_formatter.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common_widgets.dart';

class PemasukanScreen extends ConsumerWidget {
  const PemasukanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodeAktifAsync = ref.watch(periodeAktifProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pemasukan')),
      body: periodeAktifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (periode) {
          final pemasukanAsync =
              ref.watch(daftarPemasukanProvider(periode?.id));
          return pemasukanAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
            data: (list) {
              if (list.isEmpty) {
                return const EmptyState(message: 'Belum ada pemasukan');
              }
              final total = list.fold<double>(0, (s, p) => s + p.nominal);
              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pemasukan',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          AppFormatter.rupiah(total),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.success,
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
                        final p = list[i];
                        return Card(
                          child: ListTile(
                            title: Text(p.kategori,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                '${AppFormatter.tanggal(p.tanggal)}${p.keterangan != null ? " • ${p.keterangan}" : ""}'),
                            trailing: Text(
                              '+${AppFormatter.rupiah(p.nominal)}',
                              style: const TextStyle(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTambahDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }

  void _showTambahDialog(BuildContext context, WidgetRef ref) {
    final nominalController = TextEditingController();
    final keteranganController = TextEditingController();
    String kategori = AppConstants.kategoriPemasukan.first;
    DateTime tanggal = DateTime.now();
    bool loading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Pemasukan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: kategori,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: AppConstants.kategoriPemasukan
                          .where((k) => k != 'Penjualan Motor')
                          .map((k) =>
                              DropdownMenuItem(value: k, child: Text(k)))
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
                          const InputDecoration(labelText: 'Keterangan'),
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
                          final nominal = double.tryParse(
                              nominalController.text.replaceAll('.', ''));
                          if (nominal == null || nominal <= 0) return;
                          setDialogState(() => loading = true);
                          try {
                            final repo = await ref
                                .read(pemasukanRepositoryProvider.future);
                            final periodeRepo = await ref
                                .read(periodeRepositoryProvider.future);
                            final periodeAktif =
                                await periodeRepo.getPeriodeAktif();
                            await repo.tambahPemasukan(
                              tanggal: tanggal,
                              kategori: kategori,
                              nominal: nominal,
                              keterangan: keteranganController.text.trim().isEmpty
                                  ? null
                                  : keteranganController.text.trim(),
                              periodeId: periodeAktif?.id,
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
