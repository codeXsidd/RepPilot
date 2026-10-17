import 'package:flutter/material.dart';

import 'package:rep_pilot/core/constants.dart';
import 'package:rep_pilot/models/overload_recommendation.dart';

class OverloadSheet extends StatelessWidget {
  final OverloadRecommendation recommendation;
  final String weightUnit;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;
  final void Function(double? weight, int? reps) onEdit;

  const OverloadSheet({
    super.key,
    required this.recommendation,
    this.weightUnit = 'kg',
    required this.onAccept,
    required this.onDismiss,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rec = recommendation;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Progressive Overload',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rec.reasoning, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    if (rec.recommendedWeightKg != null)
                      _DetailRow(
                        label: 'Suggested weight',
                        value:
                            '${displayWeight(rec.recommendedWeightKg!, weightUnit).toStringAsFixed(1)} $weightUnit',
                      ),
                    if (rec.recommendedReps != null)
                      _DetailRow(
                        label: 'Suggested reps',
                        value: '${rec.recommendedReps}',
                      ),
                    if (rec.previousWeightKg != null) ...[
                      const Divider(height: 16),
                      _DetailRow(
                        label: 'Previous weight',
                        value:
                            '${displayWeight(rec.previousWeightKg!, weightUnit).toStringAsFixed(1)} $weightUnit',
                      ),
                    ],
                    if (rec.previousReps != null)
                      _DetailRow(
                        label: 'Previous reps',
                        value: '${rec.previousReps}',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This is a training suggestion, not medical advice.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDismiss,
                    child: const Text('Dismiss'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showEditDialog(context),
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final weightCtrl = TextEditingController(
      text: recommendation.recommendedWeightKg != null
          ? displayWeight(
              recommendation.recommendedWeightKg!,
              weightUnit,
            ).toStringAsFixed(1)
          : '',
    );
    final repsCtrl = TextEditingController(
      text: recommendation.recommendedReps?.toString() ?? '',
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Suggestion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: 'Weight ($weightUnit)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: repsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reps'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final weight = double.tryParse(weightCtrl.text);
              final reps = int.tryParse(repsCtrl.text);
              final storedWeight = weight != null
                  ? storageWeight(weight, weightUnit)
                  : null;
              Navigator.pop(ctx);
              onEdit(storedWeight, reps);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
