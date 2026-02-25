import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PremiumStudyApp());
}

class PremiumStudyApp extends StatelessWidget {
  const PremiumStudyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: const FlashcardGeneratorScreen(),
    );
  }
}

class FlashcardGeneratorScreen extends StatefulWidget {
  const FlashcardGeneratorScreen({super.key});
  @override
  State<FlashcardGeneratorScreen> createState() => _FlashcardGeneratorScreenState();
}

class _FlashcardGeneratorScreenState extends State<FlashcardGeneratorScreen> with TickerProviderStateMixin {
  bool isPlaying = false;
  bool isLearning = false;
  String? selectedFilePath;
  String fileName = "No syllabus selected";
  double _currentValue = 25.0;

  double _cardTiltX = 0.0;
  double _cardTiltY = 0.0;

  late AnimationController _bgGradientController;
  late AnimationController _hoverController;

  @override
  void initState() {
    super.initState();
    // Background shifting gradient (Extremely cheap)
    _bgGradientController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _hoverController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _bgGradientController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    HapticFeedback.heavyImpact();
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
    );

    if (result != null) {
      setState(() {
        selectedFilePath = result.files.single.path;
        fileName = result.files.single.name;
        isLearning = true; 
        isPlaying = true; 
      });
      _hoverController.repeat(reverse: true); // Only animate hover when learning

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => isLearning = false);
          _hoverController.stop(); // Stop animation to save battery
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _cardTiltX -= details.delta.dy * 0.005;
            _cardTiltY += details.delta.dx * 0.005;
            _cardTiltX = _cardTiltX.clamp(-0.15, 0.15);
            _cardTiltY = _cardTiltY.clamp(-0.15, 0.15);
          });
        },
        onPanEnd: (_) {
          setState(() { _cardTiltX = 0; _cardTiltY = 0; });
        },
        child: Stack(
          children: [
            // 1. CHEAP ANIMATED BACKGROUND (No Blur)
            _buildOptimizedBackground(),

            if (isPlaying)
              Positioned(top: 80, left: 40, child: _buildBirdFlock()),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Pushable3DButton(isLearning: isLearning, onPressed: _pickFile),
                    const Spacer(),
                    // 2. CACHED 3D CARD (RepaintBoundary)
                    RepaintBoundary(child: _build3DCard()),
                    const Spacer(),
                    Physical3DSlider(
                      value: _currentValue,
                      isLearning: isLearning,
                      onChanged: (v) => setState(() => _currentValue = v),
                    ),
                    const SizedBox(height: 40),
                    _buildControls(),
                    const SizedBox(height: 40), // SPACE FOR ADMOB BANNER
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. OPTIMIZED BACKGROUND ---
  Widget _buildOptimizedBackground() {
    return AnimatedBuilder(
      animation: _bgGradientController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (_bgGradientController.value * 0.5), -1.0),
              end: Alignment(1.0, 1.0 - (_bgGradientController.value * 0.5)),
              colors: const [
                Color(0xFF07070A), // Almost black
                Color(0xFF130E24), // Deep Purple
                Color(0xFF0A151A), // Deep Cyan
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 2. OPTIMIZED 3D CARD ---
  Widget _build3DCard() {
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        double autoTilt = isLearning ? (math.sin(_hoverController.value * math.pi * 2) * 0.05) : 0;
        double autoScale = isLearning ? 1.02 + (_hoverController.value * 0.02) : 1.0;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002) 
            ..rotateX(_cardTiltX + autoTilt)
            ..rotateY(_cardTiltY + autoTilt)
            ..scale(autoScale),
          alignment: FractionalOffset.center,
          child: Container(
            height: 380, width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              // "Fake Glass" Gradient instead of BackdropFilter
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              border: Border.all(
                color: isLearning ? Colors.cyan.withOpacity(0.5) : Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isLearning ? Colors.cyan.withOpacity(0.15) : Colors.black54, 
                  blurRadius: 30,
                  offset: Offset(_cardTiltY * -20, _cardTiltX * -20 + 15),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isLearning 
                  ? const CircularProgressIndicator(color: Colors.cyan, strokeWidth: 3)
                  : Icon(Icons.picture_as_pdf_rounded, size: 90, color: const Color(0xFF8D72E1).withOpacity(0.9)),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    fileName, 
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isLearning ? "Extracting Key Facts..." : "Ready to Generate", 
                  style: TextStyle(color: isLearning ? Colors.cyan : Colors.white54, letterSpacing: 1.2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBirdFlock() {
    return SizedBox(
      width: 250, height: 120,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(top: 0, left: 0, child: AnimatedBird(delay: 0, scale: 1.1, isAI: isLearning)),
          Positioned(top: 40, left: 70, child: AnimatedBird(delay: 450, scale: 0.9, isAI: isLearning)),
          Positioned(top: 15, left: 140, child: AnimatedBird(delay: 900, scale: 1.0, isAI: isLearning)),
        ],
      ),
    );
  }

  Widget _buildControls() { 
    final secondaryGradient = [const Color(0xFF2A2A35), const Color(0xFF15151A)];
    final secondaryLip = Colors.black;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Pushable3DIconButton(icon: Icons.tune, size: 45, iconSize: 22, topColors: secondaryGradient, lipColor: secondaryLip, iconColor: Colors.white54, onPressed: () {}),
        Pushable3DIconButton(icon: Icons.fast_rewind_rounded, size: 55, iconSize: 28, topColors: secondaryGradient, lipColor: secondaryLip, iconColor: Colors.white, onPressed: () {}),
        _playButton(), 
        Pushable3DIconButton(icon: Icons.fast_forward_rounded, size: 55, iconSize: 28, topColors: secondaryGradient, lipColor: secondaryLip, iconColor: Colors.white, onPressed: () {}),
        Pushable3DIconButton(icon: Icons.save_alt, size: 45, iconSize: 22, topColors: secondaryGradient, lipColor: secondaryLip, iconColor: Colors.white54, onPressed: () {}),
      ]
    ); 
  }

  Widget _playButton() { 
    return Pushable3DIconButton(
      icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
      size: 75, iconSize: 38,
      topColors: isPlaying ? [Colors.white, Colors.grey.shade300] : (isLearning ? [Colors.cyanAccent, Colors.cyan.shade700] : [const Color(0xFFA685FE), const Color(0xFF6C4AB6)]),
      lipColor: isPlaying ? Colors.grey.shade600 : (isLearning ? Colors.cyan.shade900 : const Color(0xFF4A2B8B)),
      iconColor: Colors.black,
      onPressed: () => setState(() => isPlaying = !isPlaying),
    );
  }
}

// --- OPTIMIZED BUTTON & SLIDER (Unchanged logically, highly efficient) ---
class Pushable3DButton extends StatefulWidget {
  final bool isLearning;
  final VoidCallback onPressed;
  const Pushable3DButton({super.key, required this.isLearning, required this.onPressed});

  @override
  State<Pushable3DButton> createState() => _Pushable3DButtonState();
}

class _Pushable3DButtonState extends State<Pushable3DButton> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { HapticFeedback.mediumImpact(); setState(() => isPressed = true); },
      onTapUp: (_) { setState(() => isPressed = false); widget.onPressed(); },
      onTapCancel: () => setState(() => isPressed = false),
      child: SizedBox(
        height: 60, width: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(bottom: 0, child: Container(height: 50, width: 240, decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), color: widget.isLearning ? Colors.cyan.shade900 : const Color(0xFF4A2B8B)))),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 50),
              bottom: isPressed ? 0 : 6, 
              child: Container(
                height: 50, width: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(colors: widget.isLearning ? [Colors.cyanAccent, Colors.cyan.shade600] : [const Color(0xFF8D72E1), const Color(0xFF6C4AB6)]),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.isLearning ? Icons.psychology : Icons.document_scanner, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(widget.isLearning ? "ANALYZING..." : "UPLOAD MATERIAL", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Physical3DSlider extends StatelessWidget {
  final double value;
  final bool isLearning;
  final ValueChanged<double> onChanged;
  const Physical3DSlider({super.key, required this.value, required this.isLearning, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        RenderBox box = context.findRenderObject() as RenderBox;
        double localDx = details.localPosition.dx.clamp(0.0, box.size.width);
        onChanged((localDx / box.size.width) * 100);
      },
      child: SizedBox(
        height: 40, width: double.infinity,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 12, width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF151515), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black87, width: 1.5),
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.9), Colors.transparent]),
              ),
            ),
            Container(
              height: 12, width: (value / 100) * (MediaQuery.of(context).size.width - 48),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: LinearGradient(colors: isLearning ? [Colors.cyan.shade900, Colors.cyan] : [const Color(0xFF4A2B8B), const Color(0xFFA685FE)])),
            ),
            Positioned(
              left: (value / 100) * (MediaQuery.of(context).size.width - 48) - 15, 
              child: Container(
                height: 30, width: 30,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF1E1E24), border: Border.all(color: isLearning ? Colors.cyan : const Color(0xFFA685FE), width: 2)),
                child: Center(child: Container(height: 10, width: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: isLearning ? Colors.cyan : const Color(0xFFA685FE)))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Pushable3DIconButton extends StatefulWidget {
  final IconData icon;
  final double size, iconSize;
  final List<Color> topColors;
  final Color lipColor, iconColor;
  final VoidCallback onPressed;
  const Pushable3DIconButton({super.key, required this.icon, required this.onPressed, this.size = 50.0, this.iconSize = 24.0, required this.topColors, required this.lipColor, required this.iconColor});

  @override
  State<Pushable3DIconButton> createState() => _Pushable3DIconButtonState();
}

class _Pushable3DIconButtonState extends State<Pushable3DIconButton> {
  bool isPressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { HapticFeedback.lightImpact(); setState(() => isPressed = true); },
      onTapUp: (_) { setState(() => isPressed = false); widget.onPressed(); },
      onTapCancel: () => setState(() => isPressed = false),
      child: SizedBox(
        height: widget.size + 8, width: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(bottom: 0, child: Container(height: widget.size, width: widget.size, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.lipColor))),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 50),
              bottom: isPressed ? 0 : 8, 
              child: Container(
                height: widget.size, width: widget.size,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: widget.topColors), border: Border.all(color: Colors.white.withOpacity(0.15), width: 1)),
                child: Center(child: Icon(widget.icon, color: widget.iconColor, size: widget.iconSize)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 3. OPTIMIZED BIRD PAINTER (Removed CPU-heavy Blurs) ---
class AnimatedBird extends StatefulWidget {
  final int delay;
  final double scale;
  final bool isAI;
  const AnimatedBird({super.key, required this.delay, this.scale = 1.0, required this.isAI});
  @override
  State<AnimatedBird> createState() => _AnimatedBirdState();
}

class _AnimatedBirdState extends State<AnimatedBird> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine);
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _controller.repeat(reverse: true); });
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -35 * _anim.value, right: -5,
              child: Opacity(
                opacity: 1 - _anim.value,
                child: Transform(
                  transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(_anim.value), 
                  child: Text(math.Random().nextBool() ? "1" : "0", style: TextStyle(color: widget.isAI ? Colors.cyanAccent : const Color(0xFFB4A2E7), fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                ),
              ),
            ),
            Transform(
              transform: Matrix4.identity()..setEntry(3, 2, 0.002)..rotateY(0.3 * math.sin(_anim.value * math.pi))..rotateX(-0.2 * _anim.value)..scale(widget.scale)..translate(0.0, -12 * _anim.value, 0.0),
              alignment: Alignment.center,
              child: CustomPaint(size: const Size(45, 40), painter: AIAgentBirdPainter(bounce: _anim.value, isAI: widget.isAI)),
            ),
          ],
        );
      },
    );
  }
}

class AIAgentBirdPainter extends CustomPainter {
  final double bounce;
  final bool isAI;
  AIAgentBirdPainter({required this.bounce, required this.isAI});

  @override
  void paint(Canvas canvas, Size size) {
    // Fake shadow (No blur)
    canvas.drawCircle(Offset(size.width * 0.4 + 5, size.height * 0.6 + 15), 8, Paint()..color = Colors.black38);

    final Rect bodyRect = Rect.fromCircle(center: Offset(size.width * 0.4, size.height * 0.6), radius: 11);
    final Paint bodyPaint = Paint()..shader = RadialGradient(center: const Alignment(-0.4, -0.4), radius: 0.9, colors: isAI ? [Colors.white, Colors.cyan, Colors.cyan.shade900] : [Colors.white, const Color(0xFF8D72E1), const Color(0xFF3B1E7A)], stops: const [0.0, 0.5, 1.0]).createShader(bodyRect);

    if (isAI) canvas.drawCircle(bodyRect.center, 15, Paint()..color = Colors.cyan.withOpacity(0.2)); // Fake glow (no blur)
    canvas.drawCircle(bodyRect.center, 11, bodyPaint);

    final topBeak = Path()..moveTo(size.width * 0.55, size.height * 0.55)..lineTo(size.width * 0.95, size.height * (0.45 - (0.1 * bounce)))..lineTo(size.width * 0.65, size.height * 0.6)..close();
    canvas.drawPath(topBeak, Paint()..color = isAI ? Colors.white : Colors.orangeAccent.shade100);

    final bottomBeak = Path()..moveTo(size.width * 0.65, size.height * 0.6)..lineTo(size.width * 0.95, size.height * (0.45 - (0.1 * bounce)))..lineTo(size.width * 0.85, size.height * (0.65 + (0.1 * bounce)))..close();
    canvas.drawPath(bottomBeak, Paint()..color = isAI ? Colors.grey.shade400 : Colors.deepOrange.shade800);

    canvas.drawCircle(Offset(size.width * 0.55, size.height * 0.48), 2.5, Paint()..color = isAI ? Colors.cyan.shade900 : Colors.black87);
    canvas.drawCircle(Offset(size.width * 0.53, size.height * 0.46), 0.8, Paint()..color = Colors.white);

    final wingPath = Path();
    wingPath.moveTo(size.width * 0.25, size.height * 0.55);
    wingPath.quadraticBezierTo(-size.width * 0.1, size.height * (0.1 + (0.8 * bounce)), size.width * 0.4, size.height * 0.75);
    wingPath.quadraticBezierTo(size.width * 0.3, size.height * 0.65, size.width * 0.25, size.height * 0.55); 

    final Paint wingPaint = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: isAI ? [Colors.cyanAccent, Colors.cyan.shade800] : [const Color(0xFFB4A2E7), const Color(0xFF4A2B8B)]).createShader(Rect.fromLTRB(0, 0, size.width, size.height));
    
    canvas.drawPath(wingPath.shift(const Offset(1, 3)), Paint()..color = Colors.black26); // Fake wing shadow (no blur)
    canvas.drawPath(wingPath, wingPaint);
  }
  @override
  bool shouldRepaint(AIAgentBirdPainter oldDelegate) => true;
}