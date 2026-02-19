import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/admin_providers.dart';

/// Adjust safety score component weights with sliders,
/// preview impact, and apply changes.
class ScoreTuningScreen extends ConsumerStatefulWidget {
  const ScoreTuningScreen({super.key});

  @override
  ConsumerState<ScoreTuningScreen> createState() => _ScoreTuningScreenState();
}

class _ScoreTuningScreenState extends ConsumerState<ScoreTuningScreen> {
  Map<String, double>? _weights;
  List<Map<String, dynamic>>? _previews;
  bool _applying = false;
  bool _previewing = false;

  static const _labels = {
    'crime_density': 'Crime Density',
    'user_flags': 'User Flags',
    'commercial': 'Commercial Areas',
    'lighting': 'Lighting',
    'population': 'Population Density',
  };

  @override
  void initState() {
    super.initState();
    _loadWeights();
  }

  Future<void> _loadWeights() async {
    final weights = await ref.read(scoreTuningServiceProvider).getWeights();
    if (mounted) setState(() => _weights = Map<String, double>.from(weights));
  }

  double get _totalWeight =>
      _weights?.values.fold<double>(0.0, (a, b) => a + b) ?? 0.0;

  bool get _isValid => (_totalWeight - 1.0).abs() < 0.01;

  Future<void> _preview() async {
    if (_weights == null) return;
    setState(() => _previewing = true);
    try {
      final previews = await ref
          .read(scoreTuningServiceProvider)
          .previewWeightChange(_weights!);
      if (mounted) setState(() => _previews = previews);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Preview failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _previewing = false);
    }
  }

  Future<void> _apply() async {
    if (_weights == null || !_isValid) return;
    setState(() => _applying = true);
    try {
      await ref.read(scoreTuningServiceProvider).applyWeights(_weights!);
      ref.invalidate(scoreWeightsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weights applied!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Safety Score Tuning')),
      body: _weights == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Component Weights',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Must sum to 1.0',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 20),

                  // Weight sliders
                  ..._labels.entries.map((e) => _WeightSlider(
                        label: e.value,
                        value: _weights![e.key] ?? 0,
                        onChanged: (v) {
                          setState(() {
                            _weights![e.key] = double.parse(v.toStringAsFixed(2));
                            _previews = null;
                          });
                        },
                      )),

                  const SizedBox(height: 16),

                  // Total indicator
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isValid
                          ? AppColors.safetySafe.withValues(alpha: 0.1)
                          : AppColors.safetyUnsafe.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          _totalWeight.toStringAsFixed(2),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isValid
                                ? AppColors.safetySafe
                                : AppColors.safetyUnsafe,
                          ),
                        ),
                        Icon(
                          _isValid ? Icons.check_circle : Icons.warning,
                          color: _isValid
                              ? AppColors.safetySafe
                              : AppColors.safetyUnsafe,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Preview button
                  OutlinedButton.icon(
                    onPressed: _previewing || !_isValid ? null : _preview,
                    icon: _previewing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.preview),
                    label: const Text('Preview Changes'),
                  ),
                  const SizedBox(height: 12),

                  // Preview results
                  if (_previews != null && _previews!.isNotEmpty) ...[
                    Text('Preview — Sample Routes',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    DataTable(
                      columns: const [
                        DataColumn(label: Text('Route')),
                        DataColumn(label: Text('Old')),
                        DataColumn(label: Text('New')),
                      ],
                      rows: _previews!
                          .map((p) => DataRow(cells: [
                                DataCell(Text(
                                    (p['route_id'] as String).substring(0, 8))),
                                DataCell(Text(
                                    (p['old_score'] as num).toStringAsFixed(1))),
                                DataCell(Text(
                                    (p['new_score'] as num).toStringAsFixed(1))),
                              ]))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Apply button
                  FilledButton.icon(
                    onPressed: _applying || !_isValid ? null : _apply,
                    icon: _applying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: const Text('Apply Weights'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _WeightSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _WeightSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(0.0, 1.0),
              min: 0,
              max: 1,
              divisions: 20,
              label: value.toStringAsFixed(2),
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(value.toStringAsFixed(2),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
