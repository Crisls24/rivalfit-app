import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rivalfit/app/theme/app_colors.dart';

import '../tabs/progress_view.dart';
import '../tabs/settings_view.dart';
import '../tabs/training_view.dart';
import 'package:rivalfit/features/league/presentation/pages/league_view.dart';

/// Shell principal de la app. Una barra inferior navega entre las 4 secciones:
/// Entrenar, Liga/amigos, Mi progreso y Ajustes. [IndexedStack] conserva el
/// estado de cada tab mientras se navega entre ellas.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      body: IndexedStack(
        index: _index,
        children: [
          TrainingView(onGoToLeague: () => setState(() => _index = 1)),
          const LeagueView(),
          const ProgressView(),
          const SettingsView(),
        ],
      ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  Widget _buildNavigationBar() {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.volt.withValues(alpha: 0.28),
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.carbon : AppColors.grayMain,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? AppColors.carbon : AppColors.grayMain,
          );
        }),
      ),
      child: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline_rounded),
            selectedIcon: Icon(Icons.play_circle_fill_rounded),
            label: 'Entrenar',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group_rounded),
            label: 'Liga',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Progreso',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}