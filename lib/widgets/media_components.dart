import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../app_theme.dart';

class AppLocalImage extends StatelessWidget {
  const AppLocalImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor = AppColors.paper2,
  });

  final String? path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final source = path?.trim() ?? '';
    Widget image;
    if (source.isEmpty) {
      image = _placeholder(Icons.image_outlined);
    } else if (_isDataImage(source)) {
      try {
        final bytes = base64Decode(source.substring(source.indexOf(',') + 1));
        image = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          frameBuilder: _frameBuilder,
          errorBuilder: (_, _, _) => _error(),
        );
      } on FormatException {
        image = _error();
      }
    } else if (_isNetworkPath(source)) {
      image = Image.network(
        source,
        width: width,
        height: height,
        fit: fit,
        frameBuilder: _frameBuilder,
        errorBuilder: (_, _, _) => _error(),
      );
    } else {
      image = Image.file(
        File(source),
        width: width,
        height: height,
        fit: fit,
        frameBuilder: _frameBuilder,
        errorBuilder: (_, _, _) => _error(),
      );
    }

    final content = Container(
      width: width,
      height: height,
      color: backgroundColor,
      alignment: Alignment.center,
      child: image,
    );
    final radius = borderRadius;
    return radius == null
        ? content
        : ClipRRect(borderRadius: radius, child: content);
  }

  Widget _frameBuilder(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (wasSynchronouslyLoaded || frame != null) return child;
    return _placeholder(Icons.image_outlined);
  }

  Widget _placeholder(IconData icon) {
    return placeholder ?? Icon(icon, color: AppColors.faint, size: 24);
  }

  Widget _error() {
    return errorWidget ?? _placeholder(Icons.broken_image_outlined);
  }

  static bool _isNetworkPath(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  static bool _isDataImage(String value) {
    return value.startsWith('data:image/') && value.contains(';base64,');
  }
}

class StoredProfileAvatar extends StatelessWidget {
  const StoredProfileAvatar({
    super.key,
    required this.path,
    required this.size,
    this.radius,
  });

  final String? path;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.person_rounded,
      size: size * 0.52,
      color: AppColors.brand,
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4E9CF), Color(0xFFC7A665)],
        ),
        borderRadius: BorderRadius.circular(radius ?? size * 0.33),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: AppLocalImage(
        path: path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        backgroundColor: Colors.transparent,
        placeholder: fallback,
        errorWidget: fallback,
      ),
    );
  }
}

class EditableAvatar extends StatelessWidget {
  const EditableAvatar({
    super.key,
    required this.path,
    required this.size,
    required this.radius,
    required this.isSaving,
    required this.onPressed,
    this.badgeSize,
    this.label,
  });

  final String? path;
  final double size;
  final double radius;
  final bool isSaving;
  final VoidCallback? onPressed;
  final double? badgeSize;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final badge = badgeSize ?? size * 0.35;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: isSaving ? null : onPressed,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              StoredProfileAvatar(path: path, size: size, radius: radius),
              Positioned(
                right: -badge * 0.18,
                bottom: -badge * 0.18,
                child: Container(
                  width: badge,
                  height: badge,
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.brass2),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: isSaving
                        ? const Padding(
                            padding: EdgeInsets.all(7),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.photo_camera_outlined,
                            size: badge * 0.52,
                            color: AppColors.brand,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 9),
          Text(
            label!,
            style: AppText.body(
              10.5,
              color: AppColors.muted,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
