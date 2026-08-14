import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/motor/motor_list_screen.dart';
import 'screens/penjualan/penjualan_screen.dart';
import 'screens/pembukuan/pembukuan_screen.dart';
import 'screens/laporan/laporan_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const ProviderScope(child: GarasiAbahBontotApp()));
}

class GarasiAbahBontotApp extends StatelessWidget {
  const GarasiAbahBontotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garasi Abah Bontot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RootShell(),
    );
  }
}

/// Shell utama dengan bottom navigation. Halaman lain (Pemasukan,
/// Pengeluaran, Kasbon, Pembagian Laba) diakses lewat menu di Dashboard
/// dan Pembukuan agar bottom nav tetap ringkas (5 tab utama).
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _currentIndex = 0;

  final _pages = const [
    DashboardScreen(),
    MotorListScreen(),
    PenjualanScreen(),
    PembukuanScreen(),
    LaporanScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.motorcycle_outlined),
            selectedIcon: Icon(Icons.motorcycle),
            label: 'Motor',
          ),
          NavigationDestination(
            icon: Icon(Icons.sell_outlined),
            selectedIcon: Icon(Icons.sell),
            label: 'Penjualan',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Pembukuan',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Laporan',
          ),
        ],
      ),
    );
  }
}
