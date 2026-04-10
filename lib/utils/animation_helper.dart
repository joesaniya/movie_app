import 'package:flutter/material.dart';
import 'dart:math' show sin;

/// Page route transitions with animations
class AnimatedPageRoute<T> extends MaterialPageRoute<T> {
  AnimatedPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
    Duration duration = const Duration(milliseconds: 500),
  }) : super(
         builder: builder,
         settings: settings,
         maintainState: maintainState,
         fullscreenDialog: fullscreenDialog,
       );

  @override
  Duration get transitionDuration => const Duration(milliseconds: 500);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
          ),
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}

/// Pop route with slide animation
class AnimatedPopRoute<T> extends MaterialPageRoute<T> {
  AnimatedPopRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) : super(
         builder: builder,
         settings: settings,
         maintainState: maintainState,
         fullscreenDialog: fullscreenDialog,
       );

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(begin: Offset.zero, end: const Offset(1.0, 0.0))
          .animate(
            CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeInOutCubic,
            ),
          ),
      child: child,
    );
  }
}

/// Fade transition for page routes
class FadePageRoute<T> extends MaterialPageRoute<T> {
  FadePageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) : super(
         builder: builder,
         settings: settings,
         maintainState: maintainState,
         fullscreenDialog: fullscreenDialog,
       );

  @override
  Duration get transitionDuration => const Duration(milliseconds: 600);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}

/// Stagger animation helper for lists
class ListAnimationHelper {
  static Future<void> animateListItems(
    List<GlobalKey<State<StatefulWidget>>> keys, {
    Duration staggerDelay = const Duration(milliseconds: 50),
  }) async {
    for (int i = 0; i < keys.length; i++) {
      await Future.delayed(
        Duration(milliseconds: i * staggerDelay.inMilliseconds),
      );
    }
  }
}

/// Scale and fade animation widget
class ScaleAndFadeAnimation extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double beginScale;
  final double beginOpacity;
  final bool animate;

  const ScaleAndFadeAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
    this.beginScale = 0.8,
    this.beginOpacity = 0.0,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, widget) {
        final scale = beginScale + (1.0 - beginScale) * value;
        final opacity = beginOpacity + (1.0 - beginOpacity) * value;

        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: widget),
        );
      },
      child: child,
    );
  }
}

/// Slide and fade animation widget
class SlideAndFadeAnimation extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Offset beginOffset;
  final bool animate;

  const SlideAndFadeAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.beginOffset = const Offset(0.0, 0.2),
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;

    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: beginOffset, end: Offset.zero),
      duration: duration,
      curve: curve,
      builder: (context, offset, widget) {
        return Opacity(
          opacity: 1.0 - (offset.dy.abs() + offset.dx.abs()) * 0.5,
          child: Transform.translate(offset: offset, child: widget),
        );
      },
      child: child,
    );
  }
}

/// Hero animation for image transitions
class HeroImageAnimation extends StatelessWidget {
  final String imageUrl;
  final String tag;
  final Widget Function(BuildContext, String) builder;

  const HeroImageAnimation({
    super.key,
    required this.imageUrl,
    required this.tag,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder:
          (flightContext, animation, direction, fromContext, toContext) {
            return Opacity(opacity: animation.value, child: toContext.widget);
          },
      child: builder(context, imageUrl),
    );
  }
}

/// Shimmer loading animation
class ShimmerAnimation extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const ShimmerAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -1.0, end: 2.0),
      duration: duration,
      curve: Curves.easeInOutQuad,
      builder: (context, value, widget) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment(-value, 0.0),
              end: Alignment(value, 0.0),
              colors: const [
                Colors.transparent,
                Colors.white12,
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: widget,
        );
      },
      child: child,
    );
  }
}

/// Bounce animation
class BounceAnimation extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final double displacement;

  const BounceAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.displacement = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.elasticOut,
      builder: (context, value, widget) {
        final bounceValue =
            (sin(value * 3.14159 * 2) * (1 - value) * displacement);
        return Transform.translate(
          offset: Offset(0, bounceValue),
          child: widget,
        );
      },
      child: child,
    );
  }
}
