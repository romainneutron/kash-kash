import 'package:flutter/material.dart';

import '../../core/utils/distance_calculator.dart';
import '../../core/utils/duration_formatter.dart';
import '../theme/app_colors.dart';

/// Celebration overlay displayed when user wins (finds the quest location).
///
/// Shows:
/// - Celebration icon
/// - "You Found It!" message
/// - Stats (elapsed time, distance walked)
/// - Done button to return to quest list
class WinOverlay extends StatelessWidget {
  /// Time taken to complete the quest.
  final Duration elapsed;

  /// Total distance walked during the quest in meters.
  final double distanceWalked;

  /// Callback when user taps the Done button.
  final VoidCallback onDone;

  /// Optional quest title to display.
  final String? questTitle;

  const WinOverlay({
    super.key,
    required this.elapsed,
    required this.distanceWalked,
    required this.onDone,
    this.questTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: Colors.black54,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration icon
                const Icon(
                  Icons.celebration,
                  size: 64,
                  color: AppColors.success,
                ),
                const SizedBox(height: 16),

                // Main message
                Text(
                  'You Found It!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Optional quest title
                if (questTitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    questTitle!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Stats
                _StatRow(
                  icon: Icons.timer_outlined,
                  label: 'Time',
                  value: DurationFormatter.formatHuman(elapsed),
                ),
                const SizedBox(height: 12),
                _StatRow(
                  icon: Icons.directions_walk,
                  label: 'Distance',
                  value: DistanceCalculator.formatDistance(distanceWalked),
                ),

                const SizedBox(height: 24),

                // Done button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onDone,
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

/// A row displaying a stat with icon, label, and value.
class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyLarge,
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
