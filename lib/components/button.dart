import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final void Function()? onTap;
  final Widget? prefixIcon;
  final bool isLoading;
  final bool isOutlined;
  
  const CustomButton({
    super.key,
    required this.text,
    this.onTap,
    this.prefixIcon,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: isOutlined 
                ? Colors.transparent 
                : theme.colorScheme.primary,
            border: isOutlined 
                ? Border.all(color: theme.colorScheme.primary, width: 2) 
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: isOutlined 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.onPrimary,
                    strokeWidth: 2.5,
                  ),
                )
              else ...[
                if (prefixIcon != null) ...[
                  prefixIcon!,
                  const SizedBox(width: 12),
                ],
                Text(
                  text,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isOutlined 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}