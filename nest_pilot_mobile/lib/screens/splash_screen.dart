import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/permission_service.dart';
import '../config/roles.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'pending_approval_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final AnimationController _ringController;
  late final AnimationController _glowController;

  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
    _checkAuth();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _ringController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    final token = await _authService.getToken();

    if (token == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
      return;
    }

    final user = await _authService.getMe();
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
      return;
    }

    if (mounted) {
      if (user.status == UserStatus.pending) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
        );
      } else {
        try {
          await PermissionService().load(force: true);
        } catch (_) {
          // If permissions fail to load we still let the user in;
          // gated UI will simply hide actions until a refresh succeeds.
        }
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen(user: user)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.55, 1.0],
              colors: [
                AppColors.heroGradientDeep,
                AppColors.primaryDark,
                AppColors.primary,
              ],
            ),
          ),
          child: Stack(
            children: [
              // ── Dot grid overlay ─────────────────────────────────────────────
              Positioned.fill(
                child: CustomPaint(painter: _DotGridPainter()),
              ),

              // ── Ambient blobs ─────────────────────────────────────────────────
              Positioned(
                top: -130,
                left: -110,
                child: _Blob(
                  size: 400,
                  color: AppColors.primaryLight.withValues(alpha: 0.18),
                ),
              ),
              Positioned(
                bottom: -150,
                right: -110,
                child: _Blob(
                  size: 380,
                  color: AppColors.heroGradientDeep.withValues(alpha: 0.85),
                ),
              ),
              Positioned(
                top: size.height * 0.40,
                right: -90,
                child: _Blob(
                  size: 240,
                  color: AppColors.accentBlue.withValues(alpha: 0.09),
                ),
              ),
              Positioned(
                top: size.height * 0.15,
                left: -70,
                child: _Blob(
                  size: 180,
                  color: AppColors.primaryLight.withValues(alpha: 0.10),
                ),
              ),

              // ── Main content ──────────────────────────────────────────────────
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Spacer(flex: 5),

                          // Logo + expanding rings
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Expanding pulse rings
                              AnimatedBuilder(
                                animation: _ringController,
                                builder: (_, _) => SizedBox(
                                  width: 280,
                                  height: 280,
                                  child: CustomPaint(
                                    painter: _RingsPainter(
                                      _ringController.value,
                                    ),
                                  ),
                                ),
                              ),

                              // Logo circle with breathing glow
                              AnimatedBuilder(
                                animation: _glowController,
                                builder: (_, child) {
                                  final g = _glowController.value;
                                  return Container(
                                    width: 92,
                                    height: 92,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.white.withValues(
                                            alpha: 0.24 + g * 0.08,
                                          ),
                                          AppColors.white.withValues(
                                            alpha: 0.09 + g * 0.05,
                                          ),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: AppColors.white.withValues(
                                          alpha: 0.26 + g * 0.14,
                                        ),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryLight
                                              .withValues(
                                                alpha: 0.15 + g * 0.30,
                                              ),
                                          blurRadius: 18 + g * 22,
                                          spreadRadius: 2 + g * 10,
                                        ),
                                      ],
                                    ),
                                    child: child,
                                  );
                                },
                                child: const Icon(
                                  Icons.home_work_rounded,
                                  size: 46,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // App name
                          const Text(
                            'Smart Nivaas',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              height: 1.0,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Tagline
                          Text(
                            'Connected Living Made Simple',
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.58),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.2,
                            ),
                          ),

                          const Spacer(flex: 6),

                          const _LoadingDots(),

                          const SizedBox(height: 52),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Background blob ───────────────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

// ── Dot grid background ───────────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    const spacing = 30.0;
    const dotR = 1.1;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotR, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter _) => false;
}

// ── Expanding rings painter ───────────────────────────────────────────────────

class _RingsPainter extends CustomPainter {
  final double progress;
  const _RingsPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const minR = 52.0;
    const maxR = 138.0;
    const rings = 3;

    for (int i = 0; i < rings; i++) {
      final t = ((progress + i / rings) % 1.0);
      final eased = t * t * (3 - 2 * t); // smoothstep
      final radius = minR + (maxR - minR) * eased;
      final opacity = (1.0 - t) * 0.38;

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 - eased * 0.6,
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.progress != progress;
}

// ── Staggered loading dots ────────────────────────────────────────────────────

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 550),
      );
      Future.delayed(Duration(milliseconds: i * 170), () {
        if (mounted) c.repeat(reverse: true);
      });
      return c;
    });
    _anims = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeInOut))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: AnimatedBuilder(
            animation: _anims[i],
            builder: (_, _) => Opacity(
              opacity: 0.25 + _anims[i].value * 0.75,
              child: Transform.scale(
                scale: 0.75 + _anims[i].value * 0.25,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.white.withValues(alpha: 0.40),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
