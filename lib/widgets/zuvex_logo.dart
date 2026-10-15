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
              width: fontSize * 1.35,
              height: fontSize * 1.35,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(fontSize * 0.35),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/app_icon.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.primary,
                  child: Icon(
                    Icons.shopping_bag_rounded,
                    size: fontSize * 0.85,
                    color: Colors.white,
                  ),
                ),
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
