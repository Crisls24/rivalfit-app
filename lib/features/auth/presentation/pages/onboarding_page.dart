import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:autohost/app/theme/app_colors.dart';
import '../widgets/glass_background.dart';
import '../widgets/gradient_button.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingData(
      icon: Icons.fitness_center,
      title: 'Entrena y Compite',
      description:
          'Compite con tus amigos en rankings semanales. Cada repeticion verificada cuenta para tu posicion.',
    ),
    _OnboardingData(
      icon: Icons.shield_outlined,
      title: 'Verificado por IA',
      description:
          'Nuestra inteligencia artificial valida cada ejercicio en tiempo real. Sin trampas, solo esfuerzo real.',
    ),
    _OnboardingData(
      icon: Icons.emoji_events_outlined,
      title: 'Alcanza la Gloria',
      description:
          'Sube de rango, desbloquea insignias y conviertete en una Leyenda. La competencia nunca se detiene.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text(
                    'Saltar',
                    style: TextStyle(color: AppColors.textGray),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              page.icon,
                              size: 60,
                              color: AppColors.primary,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 500.ms)
                              .scale(begin: const Offset(0.8, 0.8)),
                          const SizedBox(height: 40),
                          Text(
                            page.title,
                            style: const TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          )
                              .animate()
                              .fadeIn(delay: 400.ms, duration: 500.ms)
                              .slideY(begin: 0.3),
                          const SizedBox(height: 16),
                          Text(
                            page.description,
                            style: const TextStyle(
                              color: AppColors.textGray,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          )
                              .animate()
                              .fadeIn(delay: 600.ms, duration: 500.ms)
                              .slideY(begin: 0.3),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppColors.primary
                                : AppColors.textGray.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      text: _currentPage == _pages.length - 1
                          ? 'Empezar'
                          : 'Siguiente',
                      onPressed: _nextPage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
