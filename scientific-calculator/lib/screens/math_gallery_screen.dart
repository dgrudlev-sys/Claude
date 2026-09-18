import 'package:flutter/material.dart';

import '../design/typography.dart';
import '../expression/expression.dart';
import '../expression/parse/expression_parser.dart';
import '../theme/app_theme.dart';
import '../widgets/math/math_view.dart';

/// A page of rendered expressions, for looking at.
///
/// Assertions can tell you a numerator sits above a denominator; they
/// cannot tell you whether the result looks like maths. This exists so
/// the layout can be photographed and judged by eye, which is the only
/// way some of these problems show themselves.
class MathGalleryScreen extends StatelessWidget {
  const MathGalleryScreen({super.key});

  static final _samples = <({String caption, ExpressionNode expression})>[
    (
      caption: 'The expression from the brief',
      expression: BinaryNode(
        BinaryOperator.multiply,
        GroupNode(BinaryNode(
          BinaryOperator.add,
          const FractionNode(NumberNode('3'), NumberNode('4')),
          const RootNode(NumberNode('16')),
        )),
        const ExpressionParser().parse('2^2'),
      ),
    ),
    (
      caption: 'The quadratic formula',
      expression: BinaryNode(
        BinaryOperator.multiply,
        const VariableNode('x'),
        FractionNode(
          BinaryNode(
            BinaryOperator.add,
            UnaryNode(UnaryOperator.negate, const VariableNode('b')),
            RootNode(BinaryNode(
              BinaryOperator.subtract,
              const ExpressionParser().parse('b^2'),
              BinaryNode(
                BinaryOperator.multiply,
                BinaryNode(BinaryOperator.multiply, const NumberNode('4'),
                    const VariableNode('a'),
                    isImplicit: true),
                const VariableNode('c'),
                isImplicit: true,
              ),
            )),
          ),
          BinaryNode(BinaryOperator.multiply, const NumberNode('2'),
              const VariableNode('a'),
              isImplicit: true),
        ),
        isImplicit: true,
      ),
    ),
    (
      caption: 'A fraction inside a fraction',
      expression: FractionNode(
        const FractionNode(NumberNode('1'), NumberNode('2')),
        const ExpressionParser().parse('3'),
      ),
    ),
    (
      caption: 'A cube root',
      expression: const RootNode(NumberNode('27'), index: NumberNode('3')),
    ),
    (
      caption: 'Nested powers',
      expression: const ExpressionParser().parse('2^(2^(2^2))'),
    ),
    (
      caption: 'An empty fraction, waiting to be filled',
      expression: const FractionNode(
        PlaceholderNode(role: 'numerator'),
        PlaceholderNode(role: 'denominator'),
      ),
    ),
    (
      caption: 'A function of a sum',
      expression: const ExpressionParser().parse('sin(x+1)'),
    ),
    (
      caption: 'Absolute value',
      expression: AbsoluteNode(const ExpressionParser().parse('x-3')),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Rendered maths')),
      body: ListView.separated(
        padding: const EdgeInsets.all(Space.m),
        itemCount: _samples.length,
        separatorBuilder: (_, _) => const SizedBox(height: Space.m),
        itemBuilder: (context, index) {
          final sample = _samples[index];
          return Container(
            padding: const EdgeInsets.all(Space.m),
            decoration: BoxDecoration(
              color: palette.elevatedSurface,
              borderRadius: BorderRadius.circular(Radii.large),
              border: Border.all(color: palette.separator),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sample.caption,
                    style: AppType.footnote.copyWith(color: palette.secondaryLabel)),
                const SizedBox(height: Space.s),
                SizedBox(
                  height: 96,
                  width: double.infinity,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: MathView(expression: sample.expression),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
