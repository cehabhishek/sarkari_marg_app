import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loaderController;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _ringRotation;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _loaderProgress;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _loaderController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    _ringRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.linear),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _loaderProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loaderController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _loaderController.forward();

    await Future.delayed(Duration(seconds: AppConstants.splashDelay));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => HomeScreen(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1527),
      body: Stack(
        children: [
          // Grid texture
          Positioned.fill(child: _buildGridTexture()),
          // Radial glow
          Positioned.fill(child: _buildCenterGlow()),
          // Corner decorations
          _buildCornerDecor(Alignment.topLeft),
          _buildCornerDecor(Alignment.bottomRight),
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnimatedLogo(),
                const SizedBox(height: 28),
                _buildTextSection(),
                const SizedBox(height: 48),
                _buildLoaderBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridTexture() {
    return CustomPaint(painter: _GridPainter());
  }

  Widget _buildCenterGlow() {
    return Center(
      child: Container(
        width: 320,
        height: 320,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Color(0x22FF9A1F),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCornerDecor(Alignment alignment) {
    final isTopLeft = alignment == Alignment.topLeft;
    return Positioned(
      top: isTopLeft ? 52 : null,
      left: isTopLeft ? 24 : null,
      bottom: isTopLeft ? null : 40,
      right: isTopLeft ? null : 24,
      child: SizedBox(
        width: 28,
        height: 28,
        child: CustomPaint(
          painter: _CornerPainter(isTopLeft: isTopLeft),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (_, __) {
        return FadeTransition(
          opacity: _logoFade,
          child: ScaleTransition(
            scale: _logoScale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Spinning ring
                Transform.rotate(
                  angle: _ringRotation.value * 2 * 3.14159,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          const Color(0xFFFF9A1F),
                          Colors.transparent,
                          const Color(0xFFFF9A1F).withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ),
                // Inner circle
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF9A1F), Color(0xFFFF6B00)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9A1F).withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF0B1527),
                    ),
                    child: Center(
                      // Replace with: Image.asset('assets/logo.png', width: 44)
                      child: Image.asset(
                        'assets/logo.png',
                        width: 44,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.account_balance,
                          size: 40,
                          color: Color(0xFFFF9A1F),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextSection() {
    return FadeTransition(
      opacity: _textFade,
      child: SlideTransition(
        position: _textSlide,
        child: Column(
          children: [
            Text(
              'SARKARI MARG',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'सरकारी मार्ग',
              style: GoogleFonts.hind(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFFF9A1F),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 14),
            // Divider line
            Container(
              width: 50,
              height: 1.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color(0xFFFF9A1F),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'YOUR PATH TO GOVERNMENT JOBS',
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: Colors.white.withOpacity(0.35),
                letterSpacing: 2.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoaderBar() {
    return AnimatedBuilder(
      animation: _loaderProgress,
      builder: (_, __) {
        return Container(
          width: 120,
          height: 2,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            widthFactor: _loaderProgress.value,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B00), Color(0xFFFF9A1F)],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Grid texture painter
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 0.5;

    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Corner bracket painter
class _CornerPainter extends CustomPainter {
  final bool isTopLeft;
  const _CornerPainter({required this.isTopLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF9A1F).withOpacity(0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final path = Path();
    if (isTopLeft) {
      path.moveTo(0, size.height * 0.5);
      path.lineTo(0, 0);
      path.lineTo(size.width * 0.5, 0);
    } else {
      path.moveTo(size.width, size.height * 0.5);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width * 0.5, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}