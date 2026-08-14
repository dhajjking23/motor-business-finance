import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_formatter.dart';
import '../../providers/app_providers.dart';
import '../../services/export_service.dart';
import '../../widgets/common_widgets.dart';

class LaporanScreen extends ConsumerStatefulWidget {
  const LaporanScreen({super.key});

  @override
  ConsumerState<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends ConsumerState<LaporanScreen> {
  bool _exporting = false;

  Future<void> _exportPdf(int periodeId) async {
    setState(() => _exporting = true);
    try {
      final periodeRepo = await ref.read(periodeRepositoryProvider.future);
      final periode = await periodeRepo.getById(periodeId);
      final laporanService = await ref.read(laporanServiceProvider.future);
      final laporan = await laporanService.getLaporanPeriode(periodeId);
      final pembagianService =
          await ref.read(pembagianLabaServiceProvider.future);
      final preview = await pembagianService.hitungPreview(periodeId);

      final exportService = ExportService();
      final file = await exportService.exportLaporanPdf(
        periode: periode!,
        laporan: laporan,
        pembagianLaba: preview,
      );
      await exportService.printOrShare(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal export PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportExcel(int periodeId) async {
    setState(() => _exporting = true);
    try {
      final periodeRepo = await ref.read(periodeRepositoryProvider.future);
      final periode = await periodeRepo.getById(periodeId);
      final laporanService = await ref.read(laporanServiceProvider.future);
      final laporan = await laporanService.getLaporanPeriode(periodeId);

      final exportService = ExportService();
      final file = await exportService.exportLaporanExcel(
        periode: periode!,
        laporan: laporan,
      );
      await Share.shareXFiles([XFile(file.path)], text: 'Laporan Excel');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal export Excel: $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final periodeAktifAsync = ref.watch(periodeAktifProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: periodeAktifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (periode) {
          if (periode == null) {
            return const EmptyState(
              message: 'Belum ada periode aktif untuk dilaporkan',
              icon: Icons.bar_chart_outlined,
            );
          }

          final laporanAsync = ref.watch(laporanPeriodeProvider(periode.id!));

          return laporanAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
            data: (laporan) {
              return Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      Text(periode.namaPeriode,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatBox(
                              label: 'Pemasukan',
                              value: laporan.totalPemasukan,
                              color: AppTheme.success,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatBox(
                              label: 'Pengeluaran',
                              value: laporan.totalPengeluaran,
                              color: AppTheme.danger,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _StatBox(
                        label: 'Total Laba Motor',
                        value: laporan.totalLabaMotor,
                        color: AppTheme.primary,
                        fullWidth: true,
                      ),
                      const SizedBox(height: 20),
                      const SectionTitle(title: 'Laba per Motor'),
                      if (laporan.labaPerMotor.isEmpty)
                        const EmptyState(message: 'Belum ada motor terjual')
                      else
                        ...laporan.labaPerMotor.map((l) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(l.motor.namaLengkap,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                    '${l.motor.kodeMotor} • ${l.penjualan.penjual}'),
                                trailing: Text(
                                  AppFormatter.rupiah(l.laba),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: l.laba >= 0
                                        ? AppTheme.success
                                        : AppTheme.danger,
                                  ),
                                ),
                              ),
                            )),
                      const SizedBox(height: 20),
                      const SectionTitle(title: 'Pengeluaran per Kategori'),
                      if (laporan.pengeluaranPerKategori.isEmpty)
                        const EmptyState(message: 'Belum ada pengeluaran')
                      else
                        ...laporan.pengeluaranPerKategori.entries.map(
                          (e) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(e.key),
                              trailing: Text(AppFormatter.rupiah(e.value)),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const SectionTitle(title: 'Penjualan per Orang'),
                      if (laporan.penjualanPerOrang.isEmpty)
                        const EmptyState(message: 'Belum ada penjualan')
                      else
                        ...laporan.penjualanPerOrang.entries.map(
                          (e) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(e.key),
                              trailing: Text('${e.value} unit'),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_exporting)
                    Container(
                      color: Colors.black26,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: periodeAktifAsync.maybeWhen(
        data: (periode) => periode == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _showExportSheet(context, periode.id!),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Export'),
              ),
        orElse: () => null,
      ),
    );
  }

  void _showExportSheet(BuildContext context, int periodeId) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Export PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportPdf(periodeId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Export Excel'),
              onTap: () {
                Navigator.pop(context);
                _exportExcel(periodeId);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool fullWidth;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(height: 4),
          Text(
            AppFormatter.rupiah(value),
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
