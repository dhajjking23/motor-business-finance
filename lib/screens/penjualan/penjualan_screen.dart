import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_formatter.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common_widgets.dart';

class PenjualanScreen extends ConsumerWidget {
  const PenjualanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodeAktifAsync = ref.watch(periodeAktifProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Penjualan Motor')),
      body: periodeAktifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (periode) {
          final penjualanAsync =
              ref.watch(daftarPenjualanProvider(periode?.id));

          return penjualanAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
            data: (penjualanList) {
              if (penjualanList.isEmpty) {
                return const EmptyState(
                  message: 'Belum ada penjualan pada periode ini',
                  icon: Icons.sell_outlined,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: penjualanList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final p = penjualanList[index];
                  final isCalo = p.penjual == AppConstants.penjualCalo;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(p.penjual,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  if (isCalo) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Tanpa Bonus',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.orange,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(AppFormatter.tanggal(p.tanggalJual),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black45)),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Harga Jual'),
                              Text(AppFormatter.rupiah(p.hargaJual)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Modal Motor'),
                              Text(AppFormatter.rupiah(p.modalMotor)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Laba',
                                  style: TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                AppFormatter.rupiah(p.laba),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: p.laba >= 0
                                      ? AppTheme.success
                                      : AppTheme.danger,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showJualMotorSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Jual Motor'),
      ),
    );
  }

  void _showJualMotorSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _JualMotorSheet(),
    );
  }
}

class _JualMotorSheet extends ConsumerStatefulWidget {
  const _JualMotorSheet();

  @override
  ConsumerState<_JualMotorSheet> createState() => _JualMotorSheetState();
}

class _JualMotorSheetState extends ConsumerState<_JualMotorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _hargaJualController = TextEditingController();
  int? _motorIdTerpilih;
  String _penjual = AppConstants.daftarPenjual.first;
  DateTime _tanggalJual = DateTime.now();
  bool _loading = false;

  @override
  void dispose() {
    _hargaJualController.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate() || _motorIdTerpilih == null) {
      if (_motorIdTerpilih == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pilih motor terlebih dahulu')));
      }
      return;
    }
    setState(() => _loading = true);

    try {
      final repo = await ref.read(penjualanRepositoryProvider.future);
      final periodeRepo = await ref.read(periodeRepositoryProvider.future);
      final periodeAktif = await periodeRepo.getPeriodeAktif();

      await repo.jualMotor(
        motorId: _motorIdTerpilih!,
        tanggalJual: _tanggalJual,
        hargaJual:
            double.parse(_hargaJualController.text.replaceAll('.', '')),
        penjual: _penjual,
        periodeId: periodeAktif?.id,
      );

      refreshSemuaData(ref);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stokAsync = ref.watch(stokMotorTersediaProvider);
    final isCalo = _penjual == AppConstants.penjualCalo;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Jual Motor',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                stokAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Text('Error: $e'),
                  data: (stok) {
                    if (stok.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text('Tidak ada stok motor tersedia'),
                      );
                    }
                    return DropdownButtonFormField<int>(
                      value: _motorIdTerpilih,
                      decoration: const InputDecoration(labelText: 'Pilih Motor'),
                      items: stok
                          .map((m) => DropdownMenuItem(
                                value: m.id,
                                child: Text(
                                    '${m.kodeMotor} - ${m.namaLengkap}'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _motorIdTerpilih = v),
                      validator: (v) => v == null ? 'Wajib dipilih' : null,
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hargaJualController,
                  decoration: const InputDecoration(
                      labelText: 'Harga Jual', prefixText: 'Rp '),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _penjual,
                  decoration: const InputDecoration(labelText: 'Penjual'),
                  items: AppConstants.daftarPenjual
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _penjual = v!),
                ),
                if (isCalo)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Penjualan lewat Calo: laba tetap tercatat, namun '
                      'tidak ikut pembagian hadiah penjualan (bonus 10%). '
                      'Fee calo tidak dicatat sistem.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tanggal Jual'),
                  subtitle: Text(AppFormatter.tanggal(_tanggalJual)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _tanggalJual,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _tanggalJual = picked);
                    }
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _simpan,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Simpan Penjualan'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
