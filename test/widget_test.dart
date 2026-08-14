// Basic smoke test untuk Garasi Abah Bontot.
//
// Test ini hanya memastikan aplikasi bisa dibangun (build) tanpa error
// dan RootShell (bottom navigation) muncul di layar pertama.
// Test yang lebih detail untuk logika bisnis ada di:
//   - test/app_constants_test.dart
//   - test/pembagian_laba_formula_test.dart
//   - test/app_formatter_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:garasi_abah_bontot/main.dart';

void main() {
  testWidgets('App bisa dibangun dan bottom navigation muncul',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: GarasiAbahBontotApp()),
    );

    // Beri beberapa frame untuk FutureProvider selesai (baik sukses maupun
    // error, karena plugin native seperti sqflite/path_provider tidak
    // tersedia di host test tanpa setup ffi tambahan). Sengaja TIDAK pakai
    // pumpAndSettle karena CircularProgressIndicator berputar terus-menerus
    // selama data belum siap, yang akan membuat pumpAndSettle timeout.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // NavigationBar bersifat independen dari status loading data, jadi
    // harus tetap muncul baik saat data sukses, loading, maupun error.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Motor'), findsOneWidget);
    expect(find.text('Penjualan'), findsOneWidget);
    expect(find.text('Pembukuan'), findsOneWidget);
    expect(find.text('Laporan'), findsOneWidget);
  });
}
