import 'package:meta/meta.dart';

import 'calculation_step.dart';
import 'line_item_result.dart';

/// The immutable aggregated result for an entire bill or invoice.
///
/// ### Money flow
/// ```
/// originalGross  (sum of line grosses, before any discount)
///   − itemDiscountImpactOnGross
///   = subtotalGross  (sum of line grosses, after item discounts)
///   − billDiscountImpactOnGross (derived from totals)
///   = totalGross
///
/// totalGross = totalNet + totalTax
///
/// totalSaved = originalGross - totalGross
///            = itemDiscountImpactOnGross + billDiscountImpactOnGross
///
/// overallDiscountPercentage = totalSaved / originalGross × 100
/// ```
@immutable
class BillResult {
  /// Per-line computed results, in the same order as the input [items] list.
  final List<LineItemResult> lineResults;

  // ── Before any discount ─────────────────────────────────────────────────

  /// Sum of all line [LineItemResult.originalGross] values: the tax-included
  /// price the customer would pay with no discounts at all.
  final double originalGross;

  /// Reduction in gross caused by item-level discounts:
  /// `originalGross - subtotalGross`.
  final double itemDiscountImpactOnGross;

  // ── Subtotals (after item-level discounts, before bill-level discounts) ──

  /// Sum of all line [LineItemResult.net] values.
  final double subtotalNet;

  /// Sum of all line [LineItemResult.tax] values.
  final double subtotalTax;

  /// Sum of all line [LineItemResult.gross] values.
  final double subtotalGross;

  // ── Bill-level adjustments ───────────────────────────────────────────────

  /// Total bill-level discount amount by the configured apply-on basis.
  ///
  /// - If apply-on is `net`, this is the discount taken from net totals.
  /// - If apply-on is `gross`, this is the discount taken from gross totals.
  ///
  /// For fixed discounts, this matches the entered fixed value (clamped by
  /// available base). It excludes item-level discounts.
  final double billDiscountAmount;

  /// Effective reduction on gross payable total caused by bill discounts.
  ///
  /// This is always derived from totals:
  /// `subtotalGross - totalGross`.
  final double billDiscountImpactOnGross;

  /// Bill-level discount percentage for display in footer.
  ///
  /// This is the bill discount as a share of [subtotalNet] (or the entered
  /// percentage when there is a single percentage discount). It excludes
  /// item-level discounts, so it is not the overall discount; use
  /// [overallDiscountPercentage] for that.
  final double billDiscountDisplayPercentage;

  /// Bill-level discount as a share of the bill after item discounts:
  /// `billDiscountAmount / subtotalGross × 100`.
  ///
  /// Example: item discounts bring the bill to 300, then a fixed 150 bill
  /// discount is applied → 50%. Zero when [subtotalGross] is zero.
  final double billDiscountPercentageOfSubtotalGross;

  // ── Final totals (after all discounts) ──────────────────────────────────

  /// Final pre-tax total the customer owes.
  final double totalNet;

  /// Final tax portion of the bill.
  final double totalTax;

  /// Final amount the customer pays: `totalNet + totalTax`.
  final double totalGross;

  /// What the customer actually saves across all item-level and bill-level
  /// discounts, including tax removed by discounts applied on net:
  /// `originalGross - totalGross`.
  final double totalSaved;

  /// Overall discount as a percentage of [originalGross]:
  /// `totalSaved / originalGross × 100`. Zero when [originalGross] is zero.
  final double overallDiscountPercentage;

  /// Step-by-step audit trail for the bill-level discount calculations.
  /// Empty when no [billDiscounts] were provided.
  final List<CalculationStep> billSteps;

  const BillResult({
    required this.lineResults,
    required this.originalGross,
    required this.itemDiscountImpactOnGross,
    required this.subtotalNet,
    required this.subtotalTax,
    required this.subtotalGross,
    required this.billDiscountAmount,
    required this.billDiscountImpactOnGross,
    required this.billDiscountDisplayPercentage,
    required this.billDiscountPercentageOfSubtotalGross,
    required this.totalNet,
    required this.totalTax,
    required this.totalGross,
    required this.totalSaved,
    required this.overallDiscountPercentage,
    required this.billSteps,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillResult &&
          runtimeType == other.runtimeType &&
          originalGross == other.originalGross &&
          subtotalGross == other.subtotalGross &&
          totalGross == other.totalGross &&
          totalSaved == other.totalSaved &&
          overallDiscountPercentage == other.overallDiscountPercentage &&
          billDiscountImpactOnGross == other.billDiscountImpactOnGross &&
          billDiscountDisplayPercentage == other.billDiscountDisplayPercentage &&
          billDiscountPercentageOfSubtotalGross ==
              other.billDiscountPercentageOfSubtotalGross;

  @override
  int get hashCode => Object.hash(
        originalGross,
        subtotalGross,
        totalGross,
        totalSaved,
        overallDiscountPercentage,
        billDiscountImpactOnGross,
        billDiscountDisplayPercentage,
        billDiscountPercentageOfSubtotalGross,
      );

  @override
  String toString() => 'BillResult('
      'originalGross: $originalGross, '
      'subtotalGross: $subtotalGross, '
      'billDiscountAmount: $billDiscountAmount, '
      'billDiscountImpactOnGross: $billDiscountImpactOnGross, '
      'billDiscountDisplayPercentage: $billDiscountDisplayPercentage, '
      'billDiscountPercentageOfSubtotalGross: '
      '$billDiscountPercentageOfSubtotalGross, '
      'totalGross: $totalGross, '
      'totalSaved: $totalSaved, '
      'overallDiscountPercentage: $overallDiscountPercentage'
      ')';
}
