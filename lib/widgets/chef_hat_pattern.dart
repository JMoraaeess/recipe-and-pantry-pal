import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ChefHatPattern extends StatelessWidget {
  const ChefHatPattern({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: CustomPaint(
        painter: _PatternPainter(isDark: isDark),
        child: Container(),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final bool isDark;
  _PatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    const icon = LucideIcons.chefHat;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    const iconSize = 22.0;
    const spacing = 55.0;
    
    final color = isDark ? Colors.white : const Color(0xFFB33E24);
    final opacity = isDark ? 0.04 : 0.12; 


    for (double x = -iconSize; x < size.width + iconSize; x += spacing) {
      for (double y = -iconSize; y < size.height + iconSize; y += spacing) {
        final offsetX = ((y / spacing).floor() % 2 == 0) ? 0 : spacing / 2;
        
        textPainter.text = TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: iconSize,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            color: color.withOpacity(opacity),
          ),
        );
        
        textPainter.layout();
        
        canvas.save();
        canvas.translate(x + offsetX, y);
        canvas.rotate(-0.2);
        textPainter.paint(canvas, Offset.zero);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
