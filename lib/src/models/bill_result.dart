import 'package:meta/meta.dart';

import 'calculation_step.dart';
import 'line_item_result.dart';

/// The immutable aggregated result for an entire bill or invoice.
///
/// ### Money flow
/// ```
/// subtotalGross  (sum of line grosses, after item discounts)
///   − billDiscountImpactOnGross (derived from totals)
///   = totalGross
///
/// totalGross = totalNet + totalTax
///
/// totalSaved = itemDiscountSavings + billDiscountAmount
/// ```
@immutable
class BillResult {
  /// Per-line computed results, in the same order as the input [items] list.
  final List<LineItemResult> lineResults;

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
  /// This value excludes item-level discounts.
  final double billDiscountDisplayPercentage;

  // ── Final totals (after all discounts) ──────────────────────────────────

  /// Final pre-tax total the customer owes.
  final double totalNet;

  /// Final tax portion of the bill.
  final double totalTax;

  /// Final amount the customer pays: `totalNet + totalTax`.
  final double totalGross;

  /// Combined saving from all item-level and bill-level discounts.
  final double totalSaved;

  /// Step-by-step audit trail for the bill-level discount calculations.
  /// Empty when no [billDiscounts] were provided.
  final List<CalculationStep> billSteps;

  const BillResult({
    required this.lineResults,
    required this.subtotalNet,
    required this.subtotalTax,
    required this.subtotalGross,
    required this.billDiscountAmount,
    required this.billDiscountImpactOnGross,
    required this.billDiscountDisplayPercentage,
    required this.totalNet,
    required this.totalTax,
    required this.totalGross,
    required this.totalSaved,
    required this.billSteps,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillResult &&
          runtimeType == other.runtimeType &&
          subtotalGross == other.subtotalGross &&
          totalGross == other.totalGross &&
          totalSaved == other.totalSaved &&
          billDiscountImpactOnGross == other.billDiscountImpactOnGross &&
          billDiscountDisplayPercentage == other.billDiscountDisplayPercentage;

  @override
  int get hashCode => Object.hash(
        subtotalGross,
        totalGross,
        totalSaved,
        billDiscountImpactOnGross,
        billDiscountDisplayPercentage,
      );

  @override
  String toString() => 'BillResult('
      'subtotalGross: $subtotalGross, '
      'billDiscountAmount: $billDiscountAmount, '
      'billDiscountImpactOnGross: $billDiscountImpactOnGross, '
      'billDiscountDisplayPercentage: $billDiscountDisplayPercentage, '
      'totalGross: $totalGross, '
      'totalSaved: $totalSaved'
      ')';
}
