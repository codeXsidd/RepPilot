import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class PlateCalculatorScreen extends StatefulWidget {
  const PlateCalculatorScreen({super.key});

  @override
  State<PlateCalculatorScreen> createState() => _PlateCalculatorScreenState();
}

class _PlateCalculatorScreenState extends State<PlateCalculatorScreen> {
  final _targetController = TextEditingController();
  double _barWeight = 20.0;
  final Map<double, bool> _availablePlates = {
    25.0: true,
    20.0: true,
    15.0: true,
    10.0: true,
    5.0: true,
    2.5: true,
    1.25: true,
  };

  List<double> _platesPerSide = [];
  String? _error;

  static const _barOptions = [20.0, 15.0, 10.0, 7.0];

  static final Map<double, Color> _plateColors = {
    25.0: const Color(0xFFE53935),
    20.0: const Color(0xFF448AFF),
    15.0: const Color(0xFFFDD835),
    10.0: const Color(0xFF43A047),
    5.0: const Color(0xFFFFFFFF),
    2.5: const Color(0xFFE53935),
    1.25: const Color(0xFF90A4AE),
  };

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  void _calculate() {
    final target = double.tryParse(_targetController.text);
    if (target == null || target < 0) {
      setState(() {
        _error = 'Enter a valid weight';
        _platesPerSide = [];
      });
      return;
    }

    if (target < _barWeight) {
      setState(() {
        _error =
            'Target must be at least the bar weight (${_barWeight.toStringAsFixed(1)} kg)';
        _platesPerSide = [];
      });
      return;
    }

    final remaining = (target - _barWeight) / 2;
    final available =
        _availablePlates.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList()
          ..sort((a, b) => b.compareTo(a));

    if (available.isEmpty && remaining > 0) {
      setState(() {
        _error = 'No plates selected';
        _platesPerSide = [];
      });
      return;
    }

    final plates = <double>[];
    var left = remaining;

    for (final plate in available) {
      while (left >= plate - 0.001) {
        plates.add(plate);
        left -= plate;
      }
    }

    if (left > 0.01) {
      setState(() {
        _error =
            'Cannot make exactly ${target.toStringAsFixed(1)} kg with selected plates.\n'
            'Closest: ${(target - left * 2).toStringAsFixed(1)} kg';
        _platesPerSide = plates;
      });
      return;
    }

    setState(() {
      _error = null;
      _platesPerSide = plates;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Plate Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target Weight',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _targetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter target weight',
                      suffixText: 'kg',
                      suffixStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onChanged: (_) => _calculate(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bar Weight',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<double>(
                    segments: _barOptions
                        .map(
                          (w) => ButtonSegment(
                            value: w,
                            label: Text('${w.toStringAsFixed(0)} kg'),
                          ),
                        )
                        .toList(),
                    selected: {_barWeight},
                    onSelectionChanged: (v) {
                      setState(() => _barWeight = v.first);
                      _calculate();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Plates',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availablePlates.keys.map((plate) {
                      final active = _availablePlates[plate]!;
                      final color =
                          _plateColors[plate] ?? AppColors.primaryBlue;
                      return FilterChip(
                        label: Text(
                          '${plate.toStringAsFixed(plate == plate.roundToDouble()
                              ? 0
                              : plate * 10 == (plate * 10).roundToDouble()
                              ? 1
                              : 2)} kg',
                        ),
                        selected: active,
                        selectedColor: color.withValues(alpha: 0.25),
                        checkmarkColor: color,
                        avatar: CircleAvatar(
                          backgroundColor: active
                              ? color
                              : theme.colorScheme.outline.withValues(
                                  alpha: 0.3,
                                ),
                          radius: 8,
                        ),
                        onSelected: (val) {
                          setState(() => _availablePlates[plate] = val);
                          _calculate();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Card(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_platesPerSide.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plates Per Side',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _BarVisualization(
                      plates: _platesPerSide,
                      plateColors: _plateColors,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    ..._buildPlateBreakdown(theme),
                  ],
                ),
              ),
            ),
          ] else if (_error == null && _targetController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text(
                      'Bar only — no plates needed',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<Widget> _buildPlateBreakdown(ThemeData theme) {
    final counts = <double, int>{};
    for (final plate in _platesPerSide) {
      counts[plate] = (counts[plate] ?? 0) + 1;
    }

    return counts.entries.map((entry) {
      final color = _plateColors[entry.key] ?? AppColors.primaryBlue;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: entry.key == 5.0
                    ? Border.all(color: theme.colorScheme.outline, width: 1)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${entry.key.toStringAsFixed(entry.key == entry.key.roundToDouble() ? 0 : 2)} kg',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '${entry.value}× per side',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _BarVisualization extends StatelessWidget {
  final List<double> plates;
  final Map<double, Color> plateColors;
  final bool isDark;

  const _BarVisualization({
    required this.plates,
    required this.plateColors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final plate in plates.reversed) _buildPlate(plate),
            Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            for (final plate in plates) _buildPlate(plate),
          ],
        ),
      ),
    );
  }

  Widget _buildPlate(double weight) {
    final color = plateColors[weight] ?? AppColors.primaryBlue;
    final height = _plateHeight(weight);
    return Container(
      width: 10,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        border: weight == 5.0
            ? Border.all(color: Colors.grey, width: 0.5)
            : null,
      ),
    );
  }

  double _plateHeight(double weight) {
    if (weight >= 25) return 90;
    if (weight >= 20) return 82;
    if (weight >= 15) return 72;
    if (weight >= 10) return 62;
    if (weight >= 5) return 52;
    if (weight >= 2.5) return 42;
    return 32;
  }
}
