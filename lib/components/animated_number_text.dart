import 'package:flutter/material.dart';

class AnimatedNumberText extends StatelessWidget {
  final double value;
  final String unit;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final int decimalPlaces;
  final bool showComma;

  const AnimatedNumberText({
    super.key,
    required this.value,
    this.unit = '',
    this.style,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
    this.decimalPlaces = 0,
    this.showComma = false,
  });

  String _formatNumber(double number) {
    final String fixed = number.toStringAsFixed(decimalPlaces);

    if (!showComma) return fixed;

    final List<String> parts = fixed.split('.');
    final String integerPart = parts[0];
    final String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    final String withComma = integerPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    return '$withComma$decimalPart';
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0,
        end: value,
      ),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, child) {
        final String numberText = _formatNumber(animatedValue);

        return Text(
          unit.isEmpty ? numberText : '$numberText $unit',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      },
    );
  }
}