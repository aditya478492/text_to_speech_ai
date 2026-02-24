import 'dart:ui';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TravelerApp());
}

class TravelerApp extends StatelessWidget {
  const TravelerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: const PremiumPlayer(),
    );
  }
}

class PremiumPlayer extends StatefulWidget {
  const PremiumPlayer({super.key});
  @override
  State<PremiumPlayer> createState() => _PremiumPlayerState();
}

class _PremiumPlayerState extends State<PremiumPlayer> with TickerProviderStateMixin {
  bool isPlaying = false;
  bool isLearning = false; // NEW: AI Learning State
  String? selectedFilePath;
  String fileName = "No file selected";
  double _currentValue = 25.0;

  late AnimationController _glowController;
  late AnimationController _buttonPulseController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    _buttonPulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
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
        isLearning = true; // Start AI "Agent" Mode
        isPlaying = true; 
      });

      // Simulate AI learning for 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => isLearning = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // Ambient Glow
          _buildAmbientGlow(),

          // AI AGENT BIRDS (Positioned High)
          if (isPlaying)
            Positioned(
              top: 80, 
              left: 40,
              child: _buildBirdFlock(),
            ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildAIFileButton(),
                  const Spacer(),
                  _buildMainCard(),
                  const Spacer(),
                  _buildProgressSection(),
                  const SizedBox(height: 40),
                  _buildControls(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Sub-Widgets ---
  Widget _buildAmbientGlow() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Positioned(
          top: -100 + (30 * _glowController.value),
          left: -50,
          child: Container(
            width: 400, height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isLearning ? Colors.cyan : const Color(0xFF6C4AB6)).withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
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

  Widget _buildAIFileButton() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isLearning 
              ? [Colors.cyan, Colors.blueAccent] 
              : [const Color(0xFF8D72E1), const Color(0xFF6C4AB6)],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isLearning ? Icons.psychology : Icons.auto_awesome, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(isLearning ? "NEURAL MAPPING..." : "INITIALIZE AI READER",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.1)),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      height: 380, width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: isLearning ? Colors.cyan.withOpacity(0.3) : Colors.white10),
        boxShadow: [BoxShadow(color: isLearning ? Colors.cyan.withOpacity(0.1) : Colors.black54, blurRadius: 40)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            color: Colors.white.withOpacity(0.02),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isLearning 
                  ? const CircularProgressIndicator(color: Colors.cyan)
                  : Icon(Icons.picture_as_pdf_rounded, size: 100, color: const Color(0xFF8D72E1)),
                const SizedBox(height: 30),
                Text(fileName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(isLearning ? "AI Agent Learning Context..." : "Ready to Read", style: TextStyle(color: Colors.white38)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection() { return Slider(value: _currentValue, max: 100, activeColor: isLearning ? Colors.cyan : const Color(0xFF8D72E1), onChanged: (v) => setState(() => _currentValue = v)); }
  Widget _buildControls() { return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [const Icon(Icons.shuffle), const Icon(Icons.skip_previous), _playButton(), const Icon(Icons.skip_next), const Icon(Icons.repeat)]); }
  Widget _playButton() { return GestureDetector(onTap: () => setState(() => isPlaying = !isPlaying), child: CircleAvatar(radius: 40, backgroundColor: isPlaying ? Colors.white : (isLearning ? Colors.cyan : const Color(0xFF8D72E1)), child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black, size: 40))); }
}

// --- UPDATED AI AGENT BIRD COMPONENT ---

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
            // DATA BITS (0/1) instead of Music Notes when learning
            Positioned(
              top: -30 * _anim.value,
              right: -5,
              child: Opacity(
                opacity: 1 - _anim.value,
                child: Text(
                  math.Random().nextBool() ? "1" : "0",
                  style: TextStyle(
                    color: widget.isAI ? Colors.cyan : const Color(0xFFB4A2E7),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace'
                  ),
                ),
              ),
            ),
            Transform.scale(
              scale: widget.scale,
              child: Transform.translate(
                offset: Offset(0, -6 * _anim.value),
                child: CustomPaint(
                  size: const Size(35, 30),
                  painter: AIAgentBirdPainter(
                    bounce: _anim.value, 
                    isAI: widget.isAI
                  ),
                ),
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
    
    // Draw Glow if AI
    if (isAI) {
      canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.6), 12, Paint()..color = Colors.cyan.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    }

    // Body
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.6), 9, bodyPaint);
    
    // Wing
    final wingPath = Path();
    wingPath.moveTo(size.width * 0.2, size.height * 0.6);
    wingPath.quadraticBezierTo(0, size.height * (0.2 + (0.5 * bounce)), size.width * 0.3, size.height * 0.75);
    canvas.drawPath(wingPath, Paint()..color = bodyColor.withOpacity(0.6));

    // Beak
    final beakPath = Path();
    beakPath.moveTo(size.width * 0.65, size.height * 0.55);
    beakPath.lineTo(size.width * 0.9, size.height * (0.5 - (0.1 * bounce)));
    beakPath.lineTo(size.width * 0.9, size.height * (0.6 + (0.1 * bounce)));
    beakPath.close();
    canvas.drawPath(beakPath, Paint()..color = isAI ? Colors.white : Colors.orangeAccent);

    // AI Eye (Scanner)
    canvas.drawCircle(Offset(size.width * 0.52, size.height * 0.5), 1.5, Paint()..color = isAI ? Colors.white : Colors.black);
  }

  @override
  bool shouldRepaint(AIAgentBirdPainter oldDelegate) => true;
}