import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../config/ui_components.dart';

// ─────────────────────────────────────────────
// LOADING WIDGET
// ─────────────────────────────────────────────
class LoadingWidget extends StatelessWidget {
  final String? message;
  final bool isSmall;

  const LoadingWidget({super.key, this.message, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    if (isSmall) {
      return const Center(
        child: SizedBox(
          width: 22, height: 22,
          child: CircularProgressIndicator(color: AppTheme.gold, strokeWidth: 1.5),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Film reel loader
          SizedBox(
            width: 52, height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(
                  width: 52, height: 52,
                  child: CircularProgressIndicator(color: AppTheme.gold, strokeWidth: 1.5),
                ),
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.charcoal,
                    border: Border.all(color: AppTheme.goldDim, width: 1),
                  ),
                  child: const Icon(Icons.movie_outlined, color: AppTheme.gold, size: 14),
                ),
              ],
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 20),
            Text(message!, style: const TextStyle(fontFamily: 'DMSans', fontSize: 13, color: AppTheme.ashGray, letterSpacing: 0.5), textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ERROR WIDGET
// ─────────────────────────────────────────────
class ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool isSmall;

  const ErrorWidget({super.key, required this.message, this.onRetry, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    if (isSmall) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.crimson, size: 14),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontFamily: 'DMSans', color: AppTheme.crimson, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.crimson.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.crimson.withOpacity(0.25), width: 0.5),
              ),
              child: const Icon(Icons.error_outline_rounded, color: AppTheme.crimson, size: 36),
            ),
            const SizedBox(height: 20),
            const Text('Something went wrong', style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.cream)),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontFamily: 'DMSans', fontSize: 13, color: AppTheme.ashGray, height: 1.5), textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.gold, width: 1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: const Text('Try Again', style: TextStyle(fontFamily: 'DMSans', fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.gold, letterSpacing: 0.3)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EMPTY WIDGET
// ─────────────────────────────────────────────
class EmptyWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  const EmptyWidget({super.key, required this.title, required this.message, this.icon = Icons.inbox_outlined, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.goldDim.withOpacity(0.3), width: 0.5),
              ),
              child: Icon(icon, size: 40, color: AppTheme.goldDim),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.cream)),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontFamily: 'DMSans', fontSize: 13, color: AppTheme.ashGray, height: 1.6), textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.1),
                    border: Border.all(color: AppTheme.gold.withOpacity(0.4), width: 0.5),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Text('Refresh', style: TextStyle(fontFamily: 'DMSans', fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.gold, letterSpacing: 0.5)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// LOADING SHIMMER
// ─────────────────────────────────────────────
class LoadingShimmer extends StatelessWidget {
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;

  const LoadingShimmer({super.key, this.height, this.width, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return WarmShimmer(
      width: width ?? double.infinity,
      height: height ?? 16,
      borderRadius: borderRadius,
    );
  }
}

// ─────────────────────────────────────────────
// NO INTERNET WIDGET
// ─────────────────────────────────────────────
class NoInternetWidget extends StatelessWidget {
  const NoInternetWidget({super.key});

  @override
  Widget build(BuildContext context) => const OfflineBanner();
}

// ─────────────────────────────────────────────
// CONNECTING INDICATOR
// ─────────────────────────────────────────────
class ConnectingIndicator extends StatelessWidget {
  final bool isVisible;
  const ConnectingIndicator({super.key, this.isVisible = true});

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.amber.withOpacity(0.08),
        border: Border(bottom: BorderSide(color: AppTheme.amber.withOpacity(0.2), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: const AlwaysStoppedAnimation(AppTheme.amber))),
          const SizedBox(width: 10),
          const Text('Reconnecting...', style: TextStyle(fontFamily: 'DMSans', fontSize: 11, color: AppTheme.amber, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
