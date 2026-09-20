import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/app_theme.dart';

class AgroWordmark extends StatelessWidget {
  final double height;
  const AgroWordmark({super.key, this.height = 42});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/branding/agrocontrol_logo.svg',
      height: height,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      semanticsLabel: 'AgroControl',
    );
  }
}

class AgroMark extends StatelessWidget {
  final double size;
  const AgroMark({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        'assets/branding/agrocontrol_mark.svg',
        width: size,
        height: size,
        semanticsLabel: 'AgroControl',
      );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      );
}

class EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  const EmptyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(icon, size: 44, color: AppColors.darkGreen),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              if (action != null) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: onAction, child: Text(action!)),
              ],
            ],
          ),
        ),
      );
}
