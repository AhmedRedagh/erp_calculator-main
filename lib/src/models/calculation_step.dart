import 'package:meta/meta.dart';

/// Controls the UI highlight colour for a [CalculationStep] row.
enum StepHighlight {
  /// Default — no special colour.
  none,

  /// Highlight the row as a tax figure.
  tax,

  /// Highlight the row as a discount or saving.
  discount,

  /// Highlight the row as the final result.
  result,
}

/// One row in the human-readable calculation audit trail.
///
/// Steps are produced by [BillingEngine] and are intended to be rendered
/// in a UI table so users can verify every calculation.
///
/// A step is either a **section header** ([isHeader] == `true`, [value] == `null`)
/// or a **data row** with a [label], optional [formula] string, and a numeric
/// [value].
///
/// ### Example rendering
/// ```
/// ─── STEP 1 — BASE PRICE ─────────────────
///  Unit price × qty   100.00 × 2 = 200.00
/// ```
@immutable
class CalculationStep {
  /// Display label for this step (e.g. `'Unit price × qty'`).
  final String label;

  /// Optional human-readable formula (e.g. `'100.00 × 2 = 200.00'`).
  final String formula;

  /// The computed numeric result. `null` for section headers.
  final double? value;

  /// When `true`, this step should be rendered as a section header, not a
  /// data row. [value] is always `null` for headers.
  final bool isHeader;

  /// Hint for the UI to apply colour coding to this row.
  final StepHighlight highlight;

  const CalculationStep({
    required this.label,
    this.formula = '',
    this.value,
    this.isHeader = false,
    this.highlight = StepHighlight.none,
  });

  /// Convenience constructor for section-header rows.
  ///
  /// ```dart
  /// CalculationStep.header('STEP 1 — BASE PRICE')
  /// ```
  const CalculationStep.header(this.label)
      : formula = '',
        value = null,
        isHeader = true,
        highlight = StepHighlight.none;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculationStep &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          formula == other.formula &&
          value == other.value &&
          isHeader == other.isHeader &&
          highlight == other.highlight;

  @override
  int get hashCode => Object.hash(label, formula, value, isHeader, highlight);

  @override
  String toString() => isHeader
      ? 'CalculationStep.header("$label")'
      : 'CalculationStep(label: "$label", value: $value)';
}
