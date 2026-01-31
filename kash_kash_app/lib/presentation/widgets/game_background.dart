import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Gameplay state for visual feedback.
enum GameplayState {
  /// Initial state, waiting for GPS.
  initializing,

  /// User is stationary (not moving).
  stationary,

  /// User is getting closer to the target.
  gettingCloser,

  /// User is getting farther from the target.
  gettingFarther,

  /// User has won (reached the target).
  won,

  /// User abandoned the quest.
  abandoned,

  /// Error state (GPS error, etc.).
  error,
}

/// Full-screen animated color background for gameplay.
///
/// Displays different colors based on gameplay state:
/// - BLACK for stationary
/// - RED for getting closer
/// - BLUE for getting farther
/// - GREEN for won
///
/// Uses smooth color transitions for better UX.
class GameBackground extends StatelessWidget {
  /// The current gameplay state.
  final GameplayState state;

  /// Animation duration for color transitions.
  final Duration animationDuration;

  /// Optional child widget to display on top of the background.
  final Widget? child;

  const GameBackground({
    super.key,
    required this.state,
    this.animationDuration = const Duration(milliseconds: 300),
    this.child,
  });

  Color get _color => switch (state) {
        GameplayState.gettingCloser => AppColors.gettingCloser,
        GameplayState.gettingFarther => AppColors.gettingFarther,
        GameplayState.won => AppColors.won,
        GameplayState.initializing ||
        GameplayState.stationary ||
        GameplayState.abandoned ||
        GameplayState.error =>
          AppColors.stationary,
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: animationDuration,
      curve: Curves.easeInOut,
      color: _color,
      width: double.infinity,
      height: double.infinity,
      child: child,
    );
  }
}
