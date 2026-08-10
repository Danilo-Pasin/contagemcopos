import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_tokens.dart';

/// Avatar com fallback de inicial, coroa de líder, escudo de criador e borda.
class AppAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final bool isCreator;
  final bool isLeader;
  final bool hasGradientRing;
  final String? emojiFallback;

  const AppAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.radius = 24,
    this.isCreator = false,
    this.isLeader = false,
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
                memCacheWidth: 256,
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

    final badgeColor = Theme.of(context).scaffoldBackgroundColor;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        if (isLeader)
          Positioned(
            top: -4,
            right: -4,
            child: _badge('👑', badgeColor),
          ),
        if (isCreator)
          Positioned(
            top: -4,
            left: -4,
            child: _badge('🛡️', badgeColor),
          ),
      ],
    );
  }

  Widget _badge(String emoji, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 14)),
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
