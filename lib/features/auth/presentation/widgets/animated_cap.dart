import 'package:flutter/material.dart';
import 'package:Uniguide/app/theme/app_colors.dart';

/// A small graduation cap with a subtle hover/tilt animation.
class AnimatedCap extends StatefulWidget {
  const AnimatedCap({
    super.key,
    this.size = 48,
    this.color = AppColors.primary,
    this.shadowColor = const Color.fromARGB(80, 21, 122, 148),
    this.duration = const Duration(milliseconds: 2600),
  });

  final double size;
  final Color color;
  final Color shadowColor;
  final Duration duration;

  @override
  State<AnimatedCap> createState() => _AnimatedCapState();
}

class _AnimatedCapState extends State<AnimatedCap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _tilt;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _tilt = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _float = Tween<double>(begin: -2, end: 4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
        return Transform.translate(
          offset: Offset(0, _float.value),
          child: Transform.rotate(
            angle: _tilt.value,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.shadowColor,
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: Icon(
        Icons.school_rounded,
        color: widget.color,
        size: widget.size,
      ),
    );
  }
}
