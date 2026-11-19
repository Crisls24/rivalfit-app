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
  const HomePage({super.key, this.openLeague = false});

  final bool openLeague;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late int _index = widget.openLeague ? 1 : 0;
  bool _progressVisited = false;

  void _selectTab(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      if (index == 2) _progressVisited = true;
    });
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.openLeague && !oldWidget.openLeague) _index = 1;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      TrainingView(onGoToLeague: () => _selectTab(1)),
      const LeagueView(),
      _progressVisited ? const ProgressView() : const SizedBox.shrink(),
      const SettingsView(),
    ];
    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      // Las hojas modales ajustan su propio contenido con el teclado.
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < tabs.length; i++)
            TickerMode(enabled: i == _index, child: tabs[i]),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: _index == 0
              ? const Border(top: BorderSide(color: AppColors.subtleBorder))
              : null,
        ),
        child: _buildNavigationBar(),
      ),
    );
  }

  Widget _buildNavigationBar() {
    final isTraining = _index == 0;
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: isTraining
            ? TrainingView.backgroundColor
            : Colors.white,
        indicatorColor: isTraining
            ? Colors.transparent
            : AppColors.volt.withValues(alpha: 0.28),
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
        maintainBottomViewPadding: true,
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline_rounded),
            selectedIcon: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.volt,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(5),
                child: Icon(Icons.play_arrow_rounded, size: 23),
              ),
            ),
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
