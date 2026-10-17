import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:rep_pilot/core/constants.dart';
import 'package:rep_pilot/models/body_weight_entry.dart';
import 'package:rep_pilot/repositories/body_weight_repository.dart';
import 'package:rep_pilot/repositories/user_profile_repository.dart';
import 'package:rep_pilot/services/weight_analytics_service.dart';
import 'package:rep_pilot/widgets/empty_state.dart';
import 'package:rep_pilot/widgets/section_header.dart';

import 'weight_chart.dart';
import 'weight_entry_form.dart';

enum _DateRange { oneWeek, oneMonth, threeMonths, sixMonths, all }

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  static const _analytics = WeightAnalyticsService();

  List<BodyWeightEntry> _entries = [];
  String _weightUnit = 'kg';
  _DateRange _selectedRange = _DateRange.oneMonth;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final bwRepo = context.read<BodyWeightRepository>();
    final profileRepo = context.read<UserProfileRepository>();

    final entries = await bwRepo.getAll();
    final profile = await profileRepo.get();
    final unit = profile?.weightUnit ?? 'kg';

    if (!mounted) return;
    setState(() {
      _entries = entries;
      _weightUnit = unit;
      _loading = false;
    });
  }

  List<BodyWeightEntry> get _filteredEntries {
    if (_entries.isEmpty) return [];
    if (_selectedRange == _DateRange.all) return _entries;

    final now = DateTime.now();
    final cutoff = switch (_selectedRange) {
      _DateRange.oneWeek => now.subtract(const Duration(days: 7)),
      _DateRange.oneMonth => now.subtract(const Duration(days: 30)),
      _DateRange.threeMonths => now.subtract(const Duration(days: 90)),
      _DateRange.sixMonths => now.subtract(const Duration(days: 180)),
      _DateRange.all => DateTime(2000),
    };

    return _entries.where((e) => !e.date.isBefore(stripTime(cutoff))).toList();
  }

  BodyWeightEntry? get _latest => _entries.isNotEmpty ? _entries.first : null;

  double? get _sevenDayAvg =>
      _analytics.getSevenDayAverage(_entries, DateTime.now());

  ({double change, int days})? get _weightChange =>
      _analytics.getWeightChange(_entries);

  Future<void> _addOrEditEntry({BodyWeightEntry? entry}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => WeightEntryForm(
        entry: entry,
        weightUnit: _weightUnit,
        repository: context.read<BodyWeightRepository>(),
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _deleteEntry(BodyWeightEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text(
          'Delete the weight entry for '
          '${DateFormat.yMMMd().format(entry.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<BodyWeightRepository>().delete(entry.id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Body Weight')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SummaryCard(
                    latest: _latest,
                    sevenDayAvg: _sevenDayAvg,
                    weightChange: _weightChange,
                    weightUnit: _weightUnit,
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(title: 'WEIGHT TREND'),
                  _buildRangeSelector(theme),
                  const SizedBox(height: 8),
                  _buildChart(),
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'HISTORY'),
                  if (_entries.isEmpty)
                    const EmptyState(
                      icon: Icons.monitor_weight_outlined,
                      title: 'No Weight Entries',
                      description:
                          'Tap + to log your body weight. Trends and '
                          'averages will appear once you have data.',
                    )
                  else
                    ..._filteredEntries.map(
                      (e) => _WeightEntryTile(
                        entry: e,
                        weightUnit: _weightUnit,
                        onTap: () => _addOrEditEntry(entry: e),
                        onDismissed: () => _deleteEntry(e),
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditEntry(),
        tooltip: 'Log Weight',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildRangeSelector(ThemeData theme) {
    const labels = {
      _DateRange.oneWeek: '1W',
      _DateRange.oneMonth: '1M',
      _DateRange.threeMonths: '3M',
      _DateRange.sixMonths: '6M',
      _DateRange.all: 'All',
    };

    return Wrap(
      spacing: 8,
      children: _DateRange.values.map((range) {
        return ChoiceChip(
          label: Text(labels[range]!),
          selected: _selectedRange == range,
          onSelected: (selected) {
            if (selected) setState(() => _selectedRange = range);
          },
        );
      }).toList(),
    );
  }

  Widget _buildChart() {
    final filtered = _filteredEntries;
    if (filtered.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data for this period')),
      );
    }

    final sortedAsc = List<BodyWeightEntry>.from(filtered)
      ..sort((a, b) => a.date.compareTo(b.date));

    final movingAvg = _analytics.calculateMovingAverage(sortedAsc, 7);

    return WeightChart(
      entries: sortedAsc,
      movingAveragePoints: movingAvg,
      weightUnit: _weightUnit,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final BodyWeightEntry? latest;
  final double? sevenDayAvg;
  final ({double change, int days})? weightChange;
  final String weightUnit;

  const _SummaryCard({
    required this.latest,
    required this.sevenDayAvg,
    required this.weightChange,
    required this.weightUnit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitLabel = weightUnit == 'lb' ? 'lb' : 'kg';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _StatColumn(
                label: 'Latest',
                value: latest != null
                    ? '${displayWeight(latest!.weightKg, weightUnit).toStringAsFixed(1)} $unitLabel'
                    : '--',
                theme: theme,
              ),
            ),
            if (sevenDayAvg != null) ...[
              Container(
                width: 1,
                height: 40,
                color: theme.colorScheme.outlineVariant,
              ),
              Expanded(
                child: _StatColumn(
                  label: '7-day avg',
                  value:
                      '${displayWeight(sevenDayAvg!, weightUnit).toStringAsFixed(1)} $unitLabel',
                  theme: theme,
                ),
              ),
            ],
            if (weightChange != null) ...[
              Container(
                width: 1,
                height: 40,
                color: theme.colorScheme.outlineVariant,
              ),
              Expanded(
                child: _StatColumn(
                  label: 'Change',
                  value:
                      '${weightChange!.change >= 0 ? '+' : ''}${displayWeight(weightChange!.change, weightUnit).toStringAsFixed(1)} $unitLabel',
                  theme: theme,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _WeightEntryTile extends StatelessWidget {
  final BodyWeightEntry entry;
  final String weightUnit;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _WeightEntryTile({
    required this.entry,
    required this.weightUnit,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitLabel = weightUnit == 'lb' ? 'lb' : 'kg';
    final weightStr =
        '${displayWeight(entry.weightKg, weightUnit).toStringAsFixed(1)} $unitLabel';

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete_rounded, color: theme.colorScheme.onError),
      ),
      confirmDismiss: (_) async {
        onDismissed();
        return false;
      },
      child: ListTile(
        title: Text(weightStr),
        subtitle: Text(DateFormat.yMMMd().format(entry.date)),
        trailing: entry.notes.isNotEmpty
            ? Icon(
                Icons.sticky_note_2_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
