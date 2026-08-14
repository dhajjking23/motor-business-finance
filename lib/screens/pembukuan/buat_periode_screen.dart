import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';

class BuatPeriodeScreen extends ConsumerStatefulWidget {
  const BuatPeriodeScreen({super.key});

  @override
  ConsumerState<BuatPeriodeScreen> createState() => _BuatPeriodeScreenState();
}

class _BuatPeriodeScreenState extends ConsumerState<BuatPeriodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _modalController = TextEditingController(text: '0');
  DateTime _tanggalMulai = DateTime.now();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _namaController.dispose();
    _modalController.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final repo = await ref.read(periodeRepositoryProvider.future);
      await repo.buatPeriode(
        namaPeriode: _namaController.text.trim(),
        tanggalMulai: _tanggalMulai,
        modalAwal: double.tryParse(_modalController.text.replaceAll('.', '')) ?? 0,
      );
      refreshSemuaData(ref);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('StateError: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Periode Pembukuan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)),
                ),
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Periode',
                  hintText: 'Contoh: Pembukuan #001',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tanggal Mulai'),
                subtitle: Text(
                    '${_tanggalMulai.day}/${_tanggalMulai.month}/${_tanggalMulai.year}'),
                trailing: const Icon(Icons.calendar_today, size: 18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _tanggalMulai,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _tanggalMulai = picked);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modalController,
                decoration: const InputDecoration(
                  labelText: 'Modal Awal (opsional)',
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _simpan,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Buat Periode'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
