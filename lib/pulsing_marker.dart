import 'package:flutter/material.dart';

/// Google Maps jaisa pulsing blue dot - current location dikhane ke liye.
/// Ek animated "radar" circle expand/fade hota hai, andar solid dot rehta hai.
class PulsingLocationMarker extends StatefulWidget {
  final Color color;
  final double heading; // Direction indicator ke liye (degrees)
  final bool showDirectionArrow;

  const PulsingLocationMarker({
    super.key,
    required this.color,
    this.heading = 0.0,
    this.showDirectionArrow = true,
  });

  @override
  State<PulsingLocationMarker> createState() => _PulsingLocationMarkerState();
}

class _PulsingLocationMarkerState extends State<PulsingLocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulseValue = _controller.value;
        return SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Expanding fading pulse ring
              Opacity(
                opacity: (1 - pulseValue).clamp(0.0, 1.0),
                child: Container(
                  width: 60 * pulseValue,
                  height: 60 * pulseValue,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withOpacity(0.3),
                  ),
                ),
              ),
              // Outer white ring
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              // Solid center dot
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                ),
              ),
              // Direction arrow (jab heading available ho)
              if (widget.showDirectionArrow)
                Transform.translate(
                  offset: const Offset(0, -18),
                  child: Transform.rotate(
                    angle: widget.heading * 3.14159265 / 180,
                    child: Icon(Icons.navigation,
                        color: widget.color, size: 14),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}