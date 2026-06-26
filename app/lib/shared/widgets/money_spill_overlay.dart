import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

void showMoneySpill(BuildContext context) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => _MoneySpillWidget(
      onComplete: () {
        entry.remove();
      },
    ),
  );

  overlay.insert(entry);
}

class _MoneySpillWidget extends StatefulWidget {
  final VoidCallback onComplete;

  const _MoneySpillWidget({required this.onComplete});

  @override
  State<_MoneySpillWidget> createState() => _MoneySpillWidgetState();
}

class _MoneySpillWidgetState extends State<_MoneySpillWidget> {
  late ConfettiController _confettiController;
  bool _dropped = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));

    // The drop takes exactly 910ms (30% slower)
    Future.delayed(910.ms, () {
      if (mounted) {
        setState(() => _dropped = true);
        _confettiController.play();
      }
    });

    // Clean up entire overlay after 4 seconds
    Future.delayed(4.seconds, () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Path drawCoin(Size size) {
    final path = Path();
    path.addOval(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2));
    return path;
  }

  Path drawBill(Size size) {
    final path = Path();
    path.addRect(Rect.fromLTWH(0, 0, size.width * 1.5, size.height * 0.8));
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The Drop (Money Bag)
            if (!_dropped)
              Positioned(
                bottom: 40,
                child: const Text('💰', style: TextStyle(fontSize: 100))
                    .animate()
                    .slideY(
                      begin: -10,
                      end: 0,
                      duration: 910.ms,
                      curve: Curves.easeInCubic, // Gravity acceleration
                    )
                    .scaleXY(
                      begin: 1.0,
                      end: 0.8,
                      delay: 860.ms,
                      duration: 50.ms, // Squash effect at the very end
                    ),
              ),

            // The Spill (Confetti burst)
            if (_dropped)
              Positioned(
                bottom: 60,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: -pi / 2, // Blast upwards
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.05,
                  numberOfParticles: 40,
                  gravity: 0.4,
                  minBlastForce: 20,
                  maxBlastForce: 80,
                  createParticlePath: (size) =>
                      Random().nextBool() ? drawCoin(size) : drawBill(size),
                  colors: const [
                    Colors.green,
                    Colors.lightGreenAccent,
                    Colors.yellow,
                    Colors.amber,
                    Colors.orange,
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
