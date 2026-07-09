import 'package:flutter/material.dart';

import '../matrix/matrix_controller.dart';

class MatrixScreen extends StatefulWidget {
  const MatrixScreen({super.key});

  @override
  State<MatrixScreen> createState() => _MatrixScreenState();
}

class _MatrixScreenState extends State<MatrixScreen> {
  final _controller = MatrixController();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _MatrixEditor(
              label: 'Matrix A',
              data: _controller.a,
              onResize: _controller.resizeA,
              onCellChanged: _controller.setA,
            ),
            const SizedBox(height: 16),
            _MatrixEditor(
              label: 'Matrix B',
              data: _controller.b,
              onResize: _controller.resizeB,
              onCellChanged: _controller.setB,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _OpButton('A + B', () => _controller.run(MatrixOp.add)),
                _OpButton('A − B', () => _controller.run(MatrixOp.subtract)),
                _OpButton('A × B', () => _controller.run(MatrixOp.multiply)),
                _OpButton('Aᵀ', () => _controller.run(MatrixOp.transposeA)),
                _OpButton('det(A)', () => _controller.run(MatrixOp.determinantA)),
                _OpButton('A⁻¹', () => _controller.run(MatrixOp.inverseA)),
                _OpButton('rref(A)', () => _controller.run(MatrixOp.rrefA)),
              ],
            ),
            const SizedBox(height: 16),
            _ResultView(controller: _controller),
          ],
        );
      },
    );
  }
}

class _OpButton extends StatelessWidget {
  const _OpButton(this.label, this.onPressed);

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(onPressed: onPressed, child: Text(label));
  }
}

class _MatrixEditor extends StatelessWidget {
  const _MatrixEditor({
    required this.label,
    required this.data,
    required this.onResize,
    required this.onCellChanged,
  });

  final String label;
  final List<List<double>> data;
  final void Function(int rows, int cols) onResize;
  final void Function(int r, int c, double value) onCellChanged;

  @override
  Widget build(BuildContext context) {
    final rows = data.length;
    final cols = data.isEmpty ? 0 : data.first.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                _DimensionStepper(
                  label: 'rows',
                  value: rows,
                  onChanged: (v) => onResize(v, cols),
                ),
                const SizedBox(width: 8),
                _DimensionStepper(
                  label: 'cols',
                  value: cols,
                  onChanged: (v) => onResize(rows, v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var r = 0; r < rows; r++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    for (var c = 0; c < cols; c++)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: SizedBox(
                          width: 64,
                          child: TextFormField(
                            key: ValueKey('$label-$r-$c-${data[r][c]}'),
                            initialValue: _formatNum(data[r][c]),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontFamily: 'monospace'),
                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                            onChanged: (v) => onCellChanged(r, c, double.tryParse(v) ?? 0),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatNum(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
}

class _DimensionStepper extends StatelessWidget {
  const _DimensionStepper({required this.label, required this.value, required this.onChanged});

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ', style: Theme.of(context).textTheme.labelSmall),
        IconButton(
          iconSize: 16,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
        ),
        Text('$value'),
        IconButton(
          iconSize: 16,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < 6 ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.controller});

  final MatrixController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.error != null) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(controller.error!),
        ),
      );
    }
    if (controller.resultScalar != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text('Result: ${controller.resultScalar!.toStringAsFixed(6)}',
              style: Theme.of(context).textTheme.titleMedium),
        ),
      );
    }
    final matrix = controller.resultMatrix;
    if (matrix == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Result', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (var r = 0; r < matrix.rows; r++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    for (var c = 0; c < matrix.cols; c++)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          matrix.at(r, c).toStringAsFixed(4),
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
