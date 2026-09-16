import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';
import 'package:rivalfit/app/theme/app_colors.dart';
import '../widgets/primary_button.dart';

/// Onboarding de 3 slides con video de fondo. Los videos se decodifican de
/// forma lazy (solo el slide activo) y el cruce hace crossfade sincronizado
/// con el gesto del PageView.
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

  /// Controladores de video por pagina (null = aun sin inicializar). Solo el
  /// slide actual se decodifica; el resto carga bajo demanda al navegar.
  late final List<VideoPlayerController?> _controllers =
      List.filled(_pages.length, null);

  @override
  void initState() {
    super.initState();
    _ensureVideo(0);
  }

  /// Crea e inicializa el controlador de [index] si aun no existe. Al quedar
  /// listo, reproduce solo si [index] es la pagina actual.
  void _ensureVideo(int index) {
    final existing = _controllers[index];
    if (existing != null) return;

    final controller = VideoPlayerController.asset(_pages[index].videoPath);
    _controllers[index] = controller;

    controller.initialize().then((_) {
      if (!mounted) {
        controller.dispose();
        return;
      }
      controller.setLooping(true);
      controller.setVolume(0.0);
      if (_currentPage == index) {
        controller.play();
        setState(() {});
      }
    }).catchError((Object error) {
      debugPrint(
          'Error inicializando video $index (${_pages[index].videoPath}): $error');
      if (identical(_controllers[index], controller)) {
        _controllers[index] = null;
      }
      controller.dispose();
    });
  }

/// Reproduce el video de [index]; si aun no esta listo, lo crea y la reproduccion
/// la completa [_ensureVideo] al terminar de inicializar.
  void _activeVideo(int index) {
    final controller = _controllers[index];
    if (controller != null && controller.value.isInitialized) {
      controller.seekTo(Duration.zero);
      controller.play();
    } else {
      _ensureVideo(index);
    }
  }

  void _onPageChanged(int index) {
    if (_currentPage == index) return;

    // Pausar video anterior
    final previous = _controllers[_currentPage];
    if (previous != null && previous.value.isInitialized) {
      previous.pause();
    }

    _activeVideo(index);

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
      controller?.dispose();
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
          // 1. Video de fondo
          _buildVideoBackgroundLayer(),

          // 2. Oscurecimiento para legibilidad del video
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

          // 3. Contenido
          SafeArea(
            child: Column(
              children: [
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

                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPageIndicator(),
                        const SizedBox(height: 24),

                        PrimaryButton(
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
          ],
      ),
    );
  }

  /// Crossfade del video atado al gesto: pagina actual y vecina conviven y su
  /// opacidad sigue el offset del PageView (sin cortes secos al deslizar).
  Widget _buildVideoBackgroundLayer() {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, _) {
        final double pos = _pageController.hasClients
            ? (_pageController.page ?? _currentPage.toDouble())
            : _currentPage.toDouble();
        final int floor = pos.floor().clamp(0, _pages.length - 1);
        final int ceil = pos.ceil().clamp(0, _pages.length - 1);

        return Stack(
          fit: StackFit.expand,
          children: [
            for (int i = floor; i <= ceil; i++)
              if (_controllers[i]?.value.isInitialized ?? false)
                Opacity(
                  opacity: (1 - (pos - i).abs()).clamp(0.0, 1.0),
                  child: _buildVideoFill(_controllers[i]!),
                ),
          ],
        );
      },
    );
  }

  /// Rellena la pantalla con el video del controlador (BoxFit.cover).
  Widget _buildVideoFill(VideoPlayerController controller) {
    return SizedBox.expand(
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
    );
  }

  /// Contenido del slide con animaciones de entrada.
  Widget _buildSlideContent(_OnboardingData page, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono: unidad visual de marca (cuadrado lima + icono negro).
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 34,
              color: Colors.black,
            ),
          )
              .animate(key: ValueKey('icon_$index'))
              .fadeIn(duration: 500.ms, delay: 150.ms)
              .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
          const SizedBox(height: 36),

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

  /// Indicador de pagina con puntos dinamicos.
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
          ),
        ),
      ),
    );
  }
}

/// Datos de un slide: icono, titulo, descripcion y video de fondo.
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

