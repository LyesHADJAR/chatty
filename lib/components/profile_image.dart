import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Add this package

class ProfileImage extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;
  final double size;
  
  const ProfileImage({
    Key? key,
    this.imageUrl,
    required this.fallbackText,
    this.size = 40, required Color backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Check if we have a valid image URL
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      // Use CachedNetworkImage for better performance
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildPlaceholder(theme),
          errorWidget: (context, url, error) => _buildFallback(theme),
        ),
      );
    } else {
      // Show fallback avatar
      return _buildFallback(theme);
    }
  }
  
  // Placeholder widget while loading
  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: size / 3,
          height: size / 3,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
  
  // Fallback avatar with initials
  Widget _buildFallback(ThemeData theme) {
    final String initials = fallbackText
        .split(' ')
        .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
        .take(2)
        .join('');
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontSize: size / 2.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 