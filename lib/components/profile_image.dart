import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileImage extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;
  final double size;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  
  const ProfileImage({
    Key? key,
    this.imageUrl,
    required this.fallbackText,
    this.size = 52,
    this.backgroundColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultColor = backgroundColor ?? theme.colorScheme.primary;
    
    Widget child;
    
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      child = CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.onPrimary,
        ),
        errorWidget: (context, url, error) => Text(
          fallbackText.isNotEmpty ? fallbackText.substring(0, 1).toUpperCase() : '?',
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      );
    } else {
      child = Text(
        fallbackText.isNotEmpty ? fallbackText.substring(0, 1).toUpperCase() : '?',
        style: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      );
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: defaultColor,
          shape: BoxShape.circle,
          image: imageUrl != null && imageUrl!.isNotEmpty
              ? DecorationImage(
                  image: CachedNetworkImageProvider(imageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? null  // No child if we have an image as decoration
            : Center(child: child),
      ),
    );
  }
}