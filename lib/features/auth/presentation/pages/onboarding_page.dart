import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import '../widgets/glass_background.dart';
import '../widgets/gradient_button.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      icon: Icons.fitness_center,
      title: 'Entrena y Compite',
      description:
          'Compite con tus amigos en rankings semanales. Cada repeticion verificada cuenta para tu posicion.',
      videoPath: 'assets/videos/Onboarding_1.mp4',
    ),
    _OnboardingData(
      icon: Icons.shield_outlined,
      title: 'Verificado por IA',
      description:
          'Nuestra inteligencia artificial valida cada ejercicio en tiempo real. Sin trampas, solo esfuerzo real.',
      videoPath: 'assets/videos/Onboarding_2.mp4',
    ),
    _OnboardingData(
      icon: Icons.emoji_events_outlined,
      title: 'Alcanza la Gloria',
      description:
          'Sube de rango, desbloquea insignias y conviertete en una Leyenda. La competencia nunca se detiene.',
      videoPath: 'assets/videos/Onboarding_3.mp4',
    ),
  ];

  late final List<VideoPlayerController> _controllers;

  @override
  void initState() {
    super.initState();
    _initVideoControllers();
  }

  void _initVideoControllers() {
    _controllers = _pages.map((page) {
      return VideoPlayerController.asset(page.videoPath);
    }).toList();

    for (int i = 0; i < _controllers.length; i++) {
      final controller = _controllers[i];

      controller.initialize().then((_) {
        if (!mounted) return;
        controller.setLooping(true);
        controller.setVolume(0.0);
        if (_currentPage == i) {
          controller.play();
        }
        setState(() {});
      }).catchError((error) {
        debugPrint('Error inicializando video $i (${_pages[i].videoPath}): $error');
      });
    }
  }

  void _onPageChanged(int index) {
    if (_currentPage == index) return;

    // Pausar video anterior
    if (_controllers[_currentPage].value.isInitialized) {
      _controllers[_currentPage].pause();
    }
    // Reproducir nuevo video desde el inicio
    if (_controllers[index].value.isInitialized) {
      _controllers[index].seekTo(Duration.zero);
      _controllers[index].play();
    }

    setState(() {
      _currentPage = index;
    });
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
  void dispose() {
    _pageController.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Capa de Video (Fondo a pantalla completa)
          _buildVideoBackgroundLayer(),

          // 2. Capa de Oscurecimiento con degradado sutil para legibilidad sin opacar el video
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.65),
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.75),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // 3. Capa de Contenido limpia
          GlassBackground(
            showBaseGradient: false,
            showDecorations: false,
            child: SafeArea(
              child: Column(
                children: [
                  // Botón "Saltar" en esquina superior derecha
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, right: 16),
                      child: TextButton(
                        onPressed: () => context.go('/login'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textGray,
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Saltar'),
                      ),
                    ),
                  ),

                  // Contenido interactivo central con PageView
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) {
                        final page = _pages[index];
                        return _buildSlideContent(page, index);
                      },
                    ),
                  ),

                  // Indicador y botón inferior
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Indicador de página dinámico (3 puntitos)
                        _buildPageIndicator(),
                        const SizedBox(height: 24),

                        // Botón principal de acción
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
        ],
      ),
    );
  }

  /// Construye el fondo de video cubriendo el 100% de la pantalla (BoxFit.cover)
  /// de forma centrada y sin distorsión.
  Widget _buildVideoBackgroundLayer() {
    return Stack(
      fit: StackFit.expand,
      children: List.generate(_controllers.length, (index) {
        final controller = _controllers[index];
        final isCurrent = _currentPage == index;

        return AnimatedOpacity(
          opacity: isCurrent && controller.value.isInitialized ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: controller.value.isInitialized
              ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: controller.value.size.width > 0
                          ? controller.value.size.width
                          : 720,
                      height: controller.value.size.height > 0
                          ? controller.value.size.height
                          : 1280,
                      child: VideoPlayer(controller),
                    ),
                  ),
                )
              : const SizedBox.expand(),
        );
      }),
    );
  }

  /// Construye el contenido del slide con animaciones de entrada
  Widget _buildSlideContent(_OnboardingData page, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono dentro de un círculo con bordes semitransparentes
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 58,
              color: AppColors.primary,
            ),
          )
              .animate(key: ValueKey('icon_$index'))
              .fadeIn(duration: 500.ms, delay: 150.ms)
              .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
          const SizedBox(height: 36),

          // Título audaz (tamaño 26, blanco)
          Text(
            page.title,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey('title_$index'))
              .fadeIn(duration: 500.ms, delay: 300.ms)
              .slideY(begin: 0.25, end: 0, curve: Curves.easeOutQuad),
          const SizedBox(height: 16),

          // Descripción (tamaño 15, gris)
          Text(
            page.description,
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 15,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey('desc_$index'))
              .fadeIn(duration: 500.ms, delay: 450.ms)
              .slideY(begin: 0.25, end: 0, curve: Curves.easeOutQuad),
        ],
      ),
    );
  }

  /// Indicador de página con 3 puntitos dinámicos
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColors.primary
                : AppColors.textGray.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
            boxShadow: _currentPage == index
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
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
  final String videoPath;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.videoPath,
  });
}

