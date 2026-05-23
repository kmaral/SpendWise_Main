import 'dart:math';
import 'package:flutter/material.dart';

class RupeeLoader extends StatefulWidget {
  const RupeeLoader({super.key});

  @override
  State<RupeeLoader> createState() => _RupeeLoaderState();
}

class _RupeeLoaderState extends State<RupeeLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Spinning coin
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                final angle = _ctrl.value * 2 * pi;
                // Scale X from 1 → 0 → 1 as the coin spins (Y-axis flip illusion)
                final scaleX = cos(angle).abs();
                // While "facing away" (scaleX near 0), swap coin face
                final isFront = cos(angle) >= 0;

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(scaleX, 1.0, 1.0),
                  child: _CoinFace(isFront: isFront),
                );
              },
            ),
            const SizedBox(height: 36),
            const Text(
              'SpendWise',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            _DotsIndicator(),
          ],
        ),
      ),
    );
  }
}

class _CoinFace extends StatelessWidget {
  final bool isFront;
  const _CoinFace({required this.isFront});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: isFront
              ? const [Color(0xFFFFE566), Color(0xFFFFAA00)]
              : const [Color(0xFFFFCC44), Color(0xFF997700)],
          radius: 0.85,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFAA00).withValues(alpha:0.5),
            blurRadius: 24,
            spreadRadius: 4,
          ),
          const BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFFFCC44),
          width: 3,
        ),
      ),
      child: Center(
        child: isFront
            ? const Text(
                '₹',
                style: TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              )
            : const Icon(
                Icons.shield,
                color: Color(0xFF1A1A2E),
                size: 44,
              ),
      ),
    );
  }
}

// Three animated bouncing dots below the title
class _DotsIndicator extends StatefulWidget {
  @override
  State<_DotsIndicator> createState() => _DotsIndicatorState();
}

class _DotsIndicatorState extends State<_DotsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Each dot offset by 1/3 of the animation cycle
            final offset = ((_ctrl.value + i / 3.0) % 1.0);
            final bounce = sin(offset * pi).clamp(0.0, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8 + bounce * 8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.5 + bounce * 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }
}
