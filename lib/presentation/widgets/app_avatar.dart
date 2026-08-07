import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_tokens.dart';

/// Avatar com fallback de inicial, coroa de criador opcional e borda.
class AppAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final bool isCreator;
  final bool hasGradientRing;
  final String? emojiFallback;

  const AppAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.radius = 24,
    this.isCreator = false,
    this.hasGradientRing = false,
    this.emojiFallback,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().substring(0, 1).toUpperCase();
    final size = radius * 2;

    Widget avatar = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _placeholder(initial),
                errorWidget: (_, __, ___) => _placeholder(initial),
              )
            : _placeholder(initial),
      ),
    );

    if (hasGradientRing) {
      avatar = Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          gradient: AppGradients.primary,
          shape: BoxShape.circle,
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            shape: BoxShape.circle,
          ),
          child: avatar,
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        if (isCreator)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: const Text('👑', style: TextStyle(fontSize: 14)),
            ),
          ),
      ],
    );
  }

  Widget _placeholder(String initial) {
    return Container(
      color: const Color(0xFF1FB45C).withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.9,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1FB45C),
        ),
      ),
    );
  }
}
