import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../routes/presentation/providers/route_providers.dart';
import '../providers/reporting_providers.dart';

/// Post-journey screen shown after a journey completes:
/// - Journey summary
/// - Feedback prompt (star rating, accuracy, comment)
/// - Generate Report / Share / Skip buttons
class JourneyCompleteScreen extends ConsumerStatefulWidget {
  final String journeyId;

  const JourneyCompleteScreen({super.key, required this.journeyId});

  @override
  ConsumerState<JourneyCompleteScreen> createState() =>
      _JourneyCompleteScreenState();
}

class _JourneyCompleteScreenState extends ConsumerState<JourneyCompleteScreen> {
  int _safetyRating = 0;
  String? _scoreAccuracy;
  final _commentController = TextEditingController();
  bool _submitting = false;
  bool _generating = false;
  String? _reportId;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_safetyRating == 0) return;

    setState(() => _submitting = true);

    try {
      final user = ref.read(supabaseClientProvider).auth.currentUser;
      if (user == null) return;

      await ref.read(feedbackServiceProvider).submitFeedback(
            journeyId: widget.journeyId,
            userId: user.id,
            safetyRating: _safetyRating,
            scoreAccuracy: _scoreAccuracy,
            comment: _commentController.text.isNotEmpty
                ? _commentController.text
                : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _generateReport() async {
    setState(() => _generating = true);

    try {
      final user = ref.read(supabaseClientProvider).auth.currentUser;
      if (user == null) return;

      // Try to get map snapshot first
      final mapSnapshot = await ref.read(mapSnapshotServiceProvider)
          .captureSnapshot(journeyId: widget.journeyId);

      final reportId = await ref.read(srrReportGeneratorProvider)
          .generateAndUpload(
            journeyId: widget.journeyId,
            userId: user.id,
            mapSnapshot: mapSnapshot,
          );

      if (mounted) {
        setState(() => _reportId = reportId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report generated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _shareReport() async {
    if (_reportId == null) return;

    final url = await ref
        .read(reportShareServiceProvider)
        .generateShareLink(_reportId!);

    if (url != null) {
      await ref.read(reportShareServiceProvider).shareReport(reportUrl: url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journey Complete'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Success banner ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.safetySafe.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.safetySafe, size: 56),
                  const SizedBox(height: 12),
                  Text('Journey Complete!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Feedback section ──
            Text('How safe did you feel?',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),

            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starIndex = i + 1;
                return IconButton(
                  iconSize: 40,
                  onPressed: () => setState(() => _safetyRating = starIndex),
                  icon: Icon(
                    starIndex <= _safetyRating
                        ? Icons.star
                        : Icons.star_border,
                    color: starIndex <= _safetyRating
                        ? Colors.amber
                        : Colors.grey,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Score accuracy
            Text('Was the safety score accurate?',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...['accurate', 'too_safe', 'too_dangerous'].map((opt) {
              final labels = {
                'accurate': 'Yes, spot on',
                'too_safe': 'Route was less safe than shown',
                'too_dangerous': 'Route was safer than shown',
              };
              return RadioListTile<String>(
                title: Text(labels[opt]!),
                value: opt,
                groupValue: _scoreAccuracy,
                onChanged: (v) => setState(() => _scoreAccuracy = v),
                dense: true,
              );
            }),
            const SizedBox(height: 16),

            // Comment
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Comments (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // ── Action buttons ──
            FilledButton.icon(
              onPressed:
                  _submitting || _safetyRating == 0 ? null : _submitFeedback,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: const Text('Submit Feedback'),
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _generating ? null : _generateReport,
              icon: _generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf),
              label: const Text('Generate Safety Report'),
            ),
            const SizedBox(height: 12),

            if (_reportId != null)
              OutlinedButton.icon(
                onPressed: _shareReport,
                icon: const Icon(Icons.share),
                label: const Text('Share Report'),
              ),
            if (_reportId != null) const SizedBox(height: 12),

            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Skip & Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
