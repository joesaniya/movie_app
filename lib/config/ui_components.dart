import 'package:flutter/material.dart';
import 'app_theme.dart';

// ─────────────────────────────────────────────
// EDITORIAL CARD
// ─────────────────────────────────────────────
class EditorialCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final Gradient? gradient;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;

  const EditorialCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.borderColor,
    this.gradient,
    this.shadows,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(AppTheme.radiusLg);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: gradient ?? AppTheme.cardGradient,
          borderRadius: br,
          border: Border.all(
            color: borderColor ?? AppTheme.warmGray.withOpacity(0.5),
            width: 0.5,
          ),
          boxShadow: shadows ?? AppTheme.cardShadow,
        ),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// GOLD DIVIDER
// ─────────────────────────────────────────────
class GoldDivider extends StatelessWidget {
  final String? label;
  final double thickness;

  const GoldDivider({super.key, this.label, this.thickness = 0.5});

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return Container(
        height: thickness,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, AppTheme.gold, Colors.transparent],
          ),
        ),
      );
    }
    return Row(
      children: [
        Expanded(child: Container(height: thickness, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, AppTheme.goldDim])))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label!, style: const TextStyle(fontFamily: 'DMSans', fontSize: 10, color: AppTheme.goldDim, letterSpacing: 2)),
        ),
        Expanded(child: Container(height: thickness, decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppTheme.goldDim, Colors.transparent])))),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// FILM STRIP BADGE
// ─────────────────────────────────────────────
class FilmBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final bool outlined;

  const FilmBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.icon,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppTheme.gold;
    final fg = textColor ?? AppTheme.inkBlack;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : bg.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: bg.withOpacity(outlined ? 0.7 : 0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 11, color: outlined ? bg : fg.withOpacity(0.9)), const SizedBox(width: 4)],
          Text(
            label.toUpperCase(),
            style: TextStyle(fontFamily: 'DMSans', fontSize: 9, fontWeight: FontWeight.w700, color: outlined ? bg : bg, letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// GOLD BUTTON
// ─────────────────────────────────────────────
class GoldButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool outlined;
  final double? width;
  final double height;
  final Color? color;

  const GoldButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.outlined = false,
    this.width,
    this.height = 52,
    this.color,
  });

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 120), vsync: this);
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? AppTheme.gold;
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) { _ctrl.reverse(); if (!widget.isLoading) widget.onPressed?.call(); },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.outlined ? null : AppTheme.goldGradient,
            color: widget.outlined ? Colors.transparent : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: c, width: widget.outlined ? 1 : 0),
            boxShadow: widget.outlined ? null : AppTheme.goldGlow,
          ),
          child: widget.isLoading
              ? Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: widget.outlined ? c : AppTheme.inkBlack)))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[Icon(widget.icon, color: widget.outlined ? c : AppTheme.inkBlack, size: 17), const SizedBox(width: 8)],
                    Text(widget.label, style: TextStyle(fontFamily: 'DMSans', fontSize: 14, fontWeight: FontWeight.w700, color: widget.outlined ? c : AppTheme.inkBlack, letterSpacing: 0.3)),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// OFFLINE BANNER
// ─────────────────────────────────────────────
class OfflineBanner extends StatelessWidget {
  final String? message;
  const OfflineBanner({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.amber.withOpacity(0.08),
        border: Border(bottom: BorderSide(color: AppTheme.amber.withOpacity(0.25), width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: AppTheme.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.wifi_off_rounded, color: AppTheme.amber, size: 13),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message ?? 'NO CONNECTION — OFFLINE MODE',
              style: const TextStyle(fontFamily: 'DMSans', fontSize: 11, color: AppTheme.amber, fontWeight: FontWeight.w600, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CONNECTIVITY DOT
// ─────────────────────────────────────────────
class ConnectivityDot extends StatefulWidget {
  final bool isOnline;
  const ConnectivityDot({super.key, required this.isOnline});

  @override
  State<ConnectivityDot> createState() => _ConnectivityDotState();
}

class _ConnectivityDotState extends State<ConnectivityDot> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(duration: const Duration(milliseconds: 1600), vsync: this)..repeat(reverse: true);
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = widget.isOnline ? AppTheme.jade : AppTheme.amber;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (ctx, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.5 + 0.5 * _pulse.value),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.4 * _pulse.value), blurRadius: 4)],
                ),
              ),
              const SizedBox(width: 5),
              Text(
                widget.isOnline ? 'ONLINE' : 'OFFLINE',
                style: TextStyle(fontFamily: 'DMSans', fontSize: 9, fontWeight: FontWeight.w700, color: color, letterSpacing: 1.5),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// SHIMMER LOADER
// ─────────────────────────────────────────────
class WarmShimmer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const WarmShimmer({super.key, this.width = double.infinity, this.height = 16, this.borderRadius});

  @override
  State<WarmShimmer> createState() => _WarmShimmerState();
}

class _WarmShimmerState extends State<WarmShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1600), vsync: this)..repeat();
    _anim = Tween<double>(begin: -1.5, end: 2.5).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(AppTheme.radiusSm),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: [(_anim.value - 0.4).clamp(0.0, 1.0), _anim.value.clamp(0.0, 1.0), (_anim.value + 0.4).clamp(0.0, 1.0)],
            colors: const [AppTheme.charcoal, AppTheme.graphite, AppTheme.charcoal],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BACK BUTTON
// ─────────────────────────────────────────────
class FilmBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  const FilmBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.pop(context),
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: AppTheme.charcoal,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppTheme.warmGray.withOpacity(0.5), width: 0.5),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.cream, size: 16),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.icon, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, color: AppTheme.gold, size: 13),
          ),
          const SizedBox(width: 8),
        ],
        Text(title.toUpperCase(), style: const TextStyle(fontFamily: 'DMSans', fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.ashGray, letterSpacing: 2)),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─────────────────────────────────────────────
// INFO ROW TILE
// ─────────────────────────────────────────────
class InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const InfoTile({super.key, required this.icon, required this.label, required this.value, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final c = iconColor ?? AppTheme.gold;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: c, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'DMSans', fontSize: 10, color: AppTheme.ashGray, letterSpacing: 1)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontFamily: 'DMSans', fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.cream)),
          ],
        ),
      ],
    );
  }
}
