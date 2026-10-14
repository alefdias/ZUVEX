import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Logotipo oficial e identidade vetorial ZUVEX
class ZuvexLogo extends StatelessWidget {
  final double fontSize;
  final bool showSlogan;
  final bool isLightOnDark;

  const ZuvexLogo({
    super.key,
    this.fontSize = 26,
    this.showSlogan = false,
    this.isLightOnDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryTextColor = isLightOnDark ? AppColors.white : AppColors.primary;
    final secondaryTextColor = isLightOnDark ? Colors.white70 : AppColors.textSecondaryLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(fontSize * 0.22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF7052E6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(fontSize * 0.35),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.radar_rounded, // Ícone de proximidade ("Perto de você")
                size: fontSize * 0.85,
                color: Colors.white,
              ),
            ),
            SizedBox(width: fontSize * 0.35),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'ZU',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                  TextSpan(
                    text: 'VEX',
                    style: TextStyle(
                      color: isLightOnDark ? const Color(0xFFBCA6FF) : const Color(0xFF6B4EEA),
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showSlogan) ...[
          const SizedBox(height: 4),
          Text(
            'Compre e venda perto de você.',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: (fontSize * 0.42).clamp(11.0, 14.0),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ],
    );
  }
}
