import 'package:flutter/material.dart';
import '../../data/services/safety_score_service.dart';
import '../../data/services/route_ranking_service.dart';
import '../../data/models/ai_analysis_model.dart';
import '../../../../core/theme/app_colors.dart';

/// Bottom sheet showing the 5-factor safety score breakdown,
/// AI analysis summary, and confidence indicator.
class SafetyBreakdownWidget extends StatelessWidget {
  final SafetyResult breakdown;
  final AiAnalysisModel? aiAnalysis;

  const SafetyBreakdownWidget({
    super.key,
    required this.breakdown,
    this.aiAnalysis,
  });

  /// Show as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required SafetyResult breakdown,
    AiAnalysisModel? aiAnalysis,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafetyBreakdownWidget(
        breakdown: breakdown,
        aiAnalysis: aiAnalysis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = RouteRankingService.getScoreColor(breakdown.overallScore);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Icon(Icons.analytics_outlined,
                      color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  Text('Safety Breakdown',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),

              // Overall score
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Text(
                      '${breakdown.overallScore.toInt()}',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('/100',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: scoreColor)),
                        Text(
                          RouteRankingService.getScoreLabel(
                              breakdown.overallScore),
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: scoreColor,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Confidence chip
                    _buildConfidenceChip(theme),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Factor bars
              _buildFactorBar(
                  theme, 'Crime Density', breakdown.crimeScore, 0.35),
              _buildFactorBar(
                  theme, 'User Reports', breakdown.flagScore, 0.25),
              _buildFactorBar(
                  theme, 'Commercial Area', breakdown.commercialScore, 0.20),
              _buildFactorBar(
                  theme, 'Lighting', breakdown.lightingScore, 0.10),
              _buildFactorBar(
                  theme, 'Population', breakdown.populationScore, 0.10),

              // Low confidence warning
              if (RouteRankingService.shouldShowConfidenceWarning(
                  breakdown.confidence)) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber,
                          color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Limited safety data available for this area. Exercise extra caution.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.amber[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // AI Analysis section
              if (aiAnalysis != null) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      aiAnalysis!.isFallback
                          ? 'Statistical Analysis'
                          : 'AI Analysis',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Summary
                if (aiAnalysis!.summary.isNotEmpty)
                  Text(aiAnalysis!.summary,
                      style: theme.textTheme.bodyMedium),

                // Precautions
                if (aiAnalysis!.precautions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Precautions',
                      style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  ...aiAnalysis!.precautions.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                                child: Text(p,
                                    style: theme.textTheme.bodySmall)),
                          ],
                        ),
                      )),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfidenceChip(ThemeData theme) {
    final label = RouteRankingService.getConfidenceLabel(breakdown.confidence);
    final color = breakdown.confidence >= 0.8
        ? AppColors.safetySafe
        : breakdown.confidence >= 0.5
            ? AppColors.safetyModerate
            : Colors.amber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, size: 14, color: color),
          const SizedBox(width: 4),
          Text('$label confidence',
              style: theme.textTheme.labelSmall?.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildFactorBar(
      ThemeData theme, String label, double score, double weight) {
    final color = RouteRankingService.getScoreColor(score);
    final weightPercent = (weight * 100).toInt();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              Text('${score.toInt()}%',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (score / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('Weight: $weightPercent%',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
