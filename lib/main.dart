import 'dart:ui';
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

  // 3D Card Interaction variables
  double _cardTiltX = 0.0;
  double _cardTiltY = 0.0;

  late AnimationController _bgOrbController;
  late AnimationController _hoverController;

  @override
  void initState() {
    super.initState();
    _bgOrbController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
    _hoverController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgOrbController.dispose();
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

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => isLearning = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0E),
      body: GestureDetector(
        // Moving the gesture detector to the whole screen for global 3D parallax
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
            // 1. Parallax 3D Background
            _build3DBackground(),

            if (isPlaying)
              Positioned(top: 80, left: 40, child: _buildBirdFlock()),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // 2. Physical 3D Push Button
                    Pushable3DButton(
                      isLearning: isLearning,
                      onPressed: _pickFile,
                    ),
                    const Spacer(),
                    _build3DCard(),
                    const Spacer(),
                    // 3. 3D Physical Slider
                    Physical3DSlider(
                      value: _currentValue,
                      isLearning: isLearning,
                      onChanged: (v) => setState(() => _currentValue = v),
                    ),
                    const SizedBox(height: 40),
                    _buildControls(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. 3D PARALLAX BACKGROUND ---
  Widget _build3DBackground() {
    return AnimatedBuilder(
      animation: _bgOrbController,
      builder: (context, child) {
        // We apply the inverse of the card tilt to the background to create deep space parallax
        return Transform.translate(
          offset: Offset(_cardTiltY * -150, _cardTiltX * -150), 
          child: SizedBox.expand( // <--- THE FIX: Forces the Stack to fill the entire screen
            child: Stack(
              children: [
                Positioned(
                  top: -100 + (50 * math.sin(_bgOrbController.value * math.pi)),
                  left: -50 + (30 * math.cos(_bgOrbController.value * math.pi)),
                  child: Container(
                    width: 300, height: 300,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.cyan.withOpacity(0.2)),
                  ),
                ),
                Positioned(
                  bottom: -50 + (40 * math.cos(_bgOrbController.value * math.pi)),
                  right: -50 + (60 * math.sin(_bgOrbController.value * math.pi)),
                  child: Container(
                    width: 350, height: 350,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF6C4AB6).withOpacity(0.25)),
                  ),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                    child: Container(color: Colors.transparent), // The glass layer
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 2. 3D HOLOGRAPHIC CARD ---
  Widget _build3DCard() {
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        double autoTilt = isLearning ? (math.sin(_hoverController.value * math.pi * 2) * 0.05) : 0;
        double autoScale = isLearning ? 1.02 + (_hoverController.value * 0.02) : 1.0;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002) // Increased depth perspective
            ..rotateX(_cardTiltX + autoTilt)
            ..rotateY(_cardTiltY + autoTilt)
            ..scale(autoScale),
          alignment: FractionalOffset.center,
          child: _buildCardContent(),
        );
      },
    );
  }

  Widget _buildCardContent() {
    return Container(
      height: 380, width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: isLearning ? Colors.cyan.withOpacity(0.6) : Colors.white.withOpacity(0.15),
          width: 2,
        ),
        boxShadow: [
          // This creates the 3D "lift" shadow off the background
          BoxShadow(
            color: isLearning ? Colors.cyan.withOpacity(0.3) : Colors.black87, 
            blurRadius: 50,
            offset: Offset(_cardTiltY * -30, _cardTiltX * -30 + 20), // Shadow moves dynamically
            spreadRadius: isLearning ? 5 : -10,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: Colors.white.withOpacity(0.08),
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
        ),
      ),
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
    // Dark glass gradient for the secondary control buttons
    final secondaryGradient = [const Color(0xFF2A2A35), const Color(0xFF15151A)];
    final secondaryLip = Colors.black;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Pushable3DIconButton(
          icon: Icons.tune, size: 45, iconSize: 22,
          topColors: secondaryGradient, lipColor: secondaryLip, iconColor: Colors.white54,
          onPressed: () {}, 
        ),
        Pushable3DIconButton(
          icon: Icons.fast_rewind_rounded, size: 55, iconSize: 28,
          topColors: secondaryGradient, lipColor: secondaryLip, iconColor: Colors.white,
          onPressed: () {}, 
        ),
        _playButton(), 
        Pushable3DIconButton(
          icon: Icons.fast_forward_rounded, size: 55, iconSize: 28,
          topColors: secondaryGradient, lipColor: secondaryLip, iconColor: Colors.white,
          onPressed: () {}, 
        ),
        Pushable3DIconButton(
          icon: Icons.save_alt, size: 45, iconSize: 22,
          topColors: secondaryGradient, lipColor: secondaryLip, iconColor: Colors.white54,
          onPressed: () {}, 
        ),
      ]
    ); 
  }

  Widget _playButton() { 
    return Pushable3DIconButton(
      icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
      size: 75, // Bigger than the other controls
      iconSize: 38,
      // Dynamic colors based on AI and Playing states
      topColors: isPlaying 
        ? [Colors.white, Colors.grey.shade300] 
        : (isLearning ? [Colors.cyanAccent, Colors.cyan.shade700] : [const Color(0xFFA685FE), const Color(0xFF6C4AB6)]),
      lipColor: isPlaying 
        ? Colors.grey.shade600 
        : (isLearning ? Colors.cyan.shade900 : const Color(0xFF4A2B8B)),
      iconColor: Colors.black,
      onPressed: () => setState(() => isPlaying = !isPlaying),
    );
  }
}

// --- NEW: 3D PHYSICAL PUSH BUTTON ---
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
      onTapDown: (_) {
        HapticFeedback.mediumImpact();
        setState(() => isPressed = true);
      },
      onTapUp: (_) {
        setState(() => isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => isPressed = false),
      child: SizedBox(
        height: 60,
        width: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The Bottom "Lip" (Shadow layer)
            Positioned(
              bottom: 0,
              child: Container(
                height: 50, width: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: widget.isLearning ? Colors.cyan.shade900 : const Color(0xFF4A2B8B),
                  boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 10))],
                ),
              ),
            ),
            // The Top "Physical" Layer (Moves down when pressed)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 50),
              bottom: isPressed ? 0 : 6, // Moves 6 pixels down on Z/Y axis when pressed
              child: Container(
                height: 50, width: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: widget.isLearning 
                      ? [Colors.cyanAccent, Colors.cyan.shade600] 
                      : [const Color(0xFF8D72E1), const Color(0xFF6C4AB6)],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.isLearning ? Icons.psychology : Icons.document_scanner, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(widget.isLearning ? "ANALYZING..." : "UPLOAD MATERIAL",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1, color: Colors.white)),
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

// --- NEW: 3D NEUMORPHIC SLIDER ---
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
        double percent = localDx / box.size.width;
        onChanged(percent * 100);
      },
      child: SizedBox(
        height: 40,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // 1. The Carved Groove (Track) - FIXED FOR NATIVE FLUTTER
            Container(
              height: 12, width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF151515), // Deep dark base
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black87, width: 1.5), // Hard dark physical edge
                // We fake the 'inset' shadow using a gradient that is pitch black at the top and transparent at the bottom
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.9), // Deep shadow inside the top lip
                    Colors.transparent, // Catches the light at the bottom lip
                  ],
                ),
              ),
            ),
            // 2. The Filled Track (Progress)
            Container(
              height: 12, width: (value / 100) * (MediaQuery.of(context).size.width - 48),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: isLearning ? [Colors.cyan.shade900, Colors.cyan] : [const Color(0xFF4A2B8B), const Color(0xFFA685FE)],
                ),
                boxShadow: [
                  BoxShadow(color: isLearning ? Colors.cyan.withOpacity(0.5) : const Color(0xFF8D72E1).withOpacity(0.5), blurRadius: 8)
                ]
              ),
            ),
            // 3. The 3D Knob (Thumb)
            Positioned(
              left: (value / 100) * (MediaQuery.of(context).size.width - 48) - 15, // Centers the 30px thumb
              child: Container(
                height: 30, width: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E1E24),
                  border: Border.all(color: isLearning ? Colors.cyan : const Color(0xFFA685FE), width: 2),
                  boxShadow: [
                    const BoxShadow(color: Colors.black87, blurRadius: 8, offset: Offset(4, 4)), // Drop shadow
                    BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 4, offset: const Offset(-2, -2)), // Top highlight
                  ]
                ),
                child: Center(
                  child: Container(
                    height: 10, width: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLearning ? Colors.cyan : const Color(0xFFA685FE),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- AI AGENT BIRD COMPONENT (Unchanged) ---
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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
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
              top: -30 * _anim.value, right: -5,
              child: Opacity(
                opacity: 1 - _anim.value,
                child: Text(
                  math.Random().nextBool() ? "1" : "0",
                  style: TextStyle(color: widget.isAI ? Colors.cyan : const Color(0xFFB4A2E7), fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
              ),
            ),
            Transform.scale(
              scale: widget.scale,
              child: Transform.translate(
                offset: Offset(0, -6 * _anim.value),
                child: CustomPaint(size: const Size(35, 30), painter: AIAgentBirdPainter(bounce: _anim.value, isAI: widget.isAI)),
              ),
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
    final bodyColor = isAI ? Colors.cyan : const Color(0xFF8D72E1);
    final bodyPaint = Paint()..color = bodyColor;
    if (isAI) canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.6), 12, Paint()..color = Colors.cyan.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.6), 9, bodyPaint);
    final wingPath = Path();
    wingPath.moveTo(size.width * 0.2, size.height * 0.6);
    wingPath.quadraticBezierTo(0, size.height * (0.2 + (0.5 * bounce)), size.width * 0.3, size.height * 0.75);
    canvas.drawPath(wingPath, Paint()..color = bodyColor.withOpacity(0.6));
    final beakPath = Path();
    beakPath.moveTo(size.width * 0.65, size.height * 0.55);
    beakPath.lineTo(size.width * 0.9, size.height * (0.5 - (0.1 * bounce)));
    beakPath.lineTo(size.width * 0.9, size.height * (0.6 + (0.1 * bounce)));
    beakPath.close();
    canvas.drawPath(beakPath, Paint()..color = isAI ? Colors.white : Colors.orangeAccent);
    canvas.drawCircle(Offset(size.width * 0.52, size.height * 0.5), 1.5, Paint()..color = isAI ? Colors.white : Colors.black);
  }

  @override
  bool shouldRepaint(AIAgentBirdPainter oldDelegate) => true;
}

// --- NEW: 3D PHYSICAL CIRCULAR BUTTON ---
class Pushable3DIconButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final List<Color> topColors;
  final Color lipColor;
  final Color iconColor;
  final VoidCallback onPressed;

  const Pushable3DIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 50.0,
    this.iconSize = 24.0,
    required this.topColors,
    required this.lipColor,
    required this.iconColor,
  });

  @override
  State<Pushable3DIconButton> createState() => _Pushable3DIconButtonState();
}

class _Pushable3DIconButtonState extends State<Pushable3DIconButton> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => isPressed = true);
      },
      onTapUp: (_) {
        setState(() => isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => isPressed = false),
      child: SizedBox(
        height: widget.size + 8, // Extra 8px for the travel distance
        width: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. The Bottom "Lip" (Shadow layer)
            Positioned(
              bottom: 0,
              child: Container(
                height: widget.size, width: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.lipColor,
                  boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 5))],
                ),
              ),
            ),
            // 2. The Top "Physical" Layer (Moves down when pressed)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 50),
              bottom: isPressed ? 0 : 8, // Moves down 8 pixels to meet the lip
              child: Container(
                height: widget.size, width: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.topColors,
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                ),
                child: Center(
                  child: Icon(widget.icon, color: widget.iconColor, size: widget.iconSize),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

