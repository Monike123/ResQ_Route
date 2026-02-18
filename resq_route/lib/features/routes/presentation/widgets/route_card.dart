import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/route_model.dart';

/// Route selection card showing distance, duration, safety score, and label.
class RouteCard extends StatelessWidget {
  final RouteModel route;
  final bool isSelected;
  final VoidCallback onTap;

  const RouteCard({
    super.key,
    required this.route,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                _buildRouteIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (route.routeIndex == 0)
                        Text(
                          'Recommended',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.safetySafe,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildScoreBadge(theme),
              ],
            ),
            const SizedBox(height: 12),

            // Stats row
            Row(
              children: [
                _buildStat(
                  Icons.straighten,
                  '${route.distanceKm.toStringAsFixed(1)} km',
                  theme,
                ),
                const SizedBox(width: 20),
                _buildStat(
                  Icons.schedule,
                  '${route.durationMin} min',
                  theme,
                ),
              ],
            ),

            // Select button
            if (isSelected) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('START JOURNEY'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRouteIcon() {
    final icons = [Icons.shield_outlined, Icons.balance, Icons.speed];
    final colors = [AppColors.safetySafe, AppColors.safetyModerate, AppColors.primary];
    final index = route.routeIndex.clamp(0, 2);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors[index].withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icons[index], color: colors[index], size: 22),
    );
  }

  Widget _buildScoreBadge(ThemeData theme) {
    if (route.safetyScore == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Scoring...',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final score = route.safetyScore!;
    final color = score >= 80
        ? AppColors.safetySafe
        : score >= 60
            ? AppColors.safetyModerate
            : AppColors.safetyUnsafe;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '🛡️ ${score.round()}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String text, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
