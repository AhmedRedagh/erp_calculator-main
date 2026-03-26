import '../enums/discount_apply_on.dart';
import '../enums/discount_type.dart';
import '../models/bill_discount.dart';
import '../models/bill_result.dart';
import '../models/calculation_step.dart';
import '../models/line_item.dart';
import 'line_item_calculator.dart';

/// The core ERP billing engine.
///
/// **Design principles:**
/// - Pure function — no mutable state, no side effects.
/// - Safe to call on every keystroke or from any isolate.
/// - All monetary values in the output are rounded to 2 decimal places.
///
/// ### Calculation order
/// 1. Each [LineItem] is calculated independently (tax + item discount).
/// 2. Line results are summed into subtotals.
/// 3. [BillDiscount]s are applied sequentially to the running totals.
///
/// ### Example
/// ```dart
/// final result = BillingEngine.calculate(
///   items: [
///     LineItem(
///       id: '1',
///       name: 'Product A',
///       unitPrice: 100,
///       qty: 2,
///       taxMode: TaxMode.exclusive,
///       discountValue: 10,
///       discountType: DiscountType.percentage,
///       discountApplyOn: DiscountApplyOn.gross,
///     ),
///   ],
///   billDiscounts: [],
///   globalTaxRate: 15,
/// );
/// print(result.totalGross); // 207.00
/// ```
abstract final class BillingEngine {
  /// Calculates the full bill and returns an immutable [BillResult].
  ///
  /// Parameters:
  /// - [items] — line items to include. Must not be empty.
  /// - [billDiscounts] — zero or more bill-level discounts applied after
  ///   line totals are summed.
  /// - [globalTaxRate] — tax percentage (0–100) used for any [LineItem] that
  ///   does not have a [LineItem.taxRateOverride].
  ///
  /// Throws [ArgumentError] if [items] is empty or [globalTaxRate] is negative.
  static BillResult calculate({
    required List<LineItem> items,
    required List<BillDiscount> billDiscounts,
    required double globalTaxRate,
  }) {
    _validate(items, globalTaxRate);

    final lineResults = [
      for (final item in items) LineItemCalculator.calculate(item, globalTaxRate),
    ];

    final subtotalNet = lineResults.fold(0.0, (sum, r) => sum + r.net);
    final subtotalTax = lineResults.fold(0.0, (sum, r) => sum + r.tax);
    final subtotalGross = lineResults.fold(0.0, (sum, r) => sum + r.gross);
    final itemDiscountSavings =
        lineResults.fold(0.0, (sum, r) => sum + r.discountAmount);

    final (:totalNet, :totalGross, :billSteps) = _applyBillDiscounts(
      billDiscounts: billDiscounts,
      subtotalNet: subtotalNet,
      subtotalGross: subtotalGross,
      globalTaxRate: globalTaxRate,
    );

    final totalTax = totalGross - totalNet;
    final billDiscountAmount = subtotalGross - totalGross;

    return BillResult(
      lineResults: lineResults,
      subtotalNet: subtotalNet,
      subtotalTax: subtotalTax,
      subtotalGross: subtotalGross,
      billDiscountAmount: billDiscountAmount,
      totalNet: totalNet,
      totalTax: totalTax,
      totalGross: totalGross,
      totalSaved: itemDiscountSavings + billDiscountAmount,
      billSteps: billSteps,
    );
  }

  // ── Input validation ─────────────────────────────────────────────────────

  static void _validate(List<LineItem> items, double globalTaxRate) {
    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items', 'Must contain at least one LineItem.');
    }
    if (globalTaxRate < 0) {
      throw ArgumentError.value(
        globalTaxRate,
        'globalTaxRate',
        'Must be ≥ 0.',
      );
    }
  }

  // ── Bill-level discounts ─────────────────────────────────────────────────

  /// Applies each [BillDiscount] in sequence to the running net/gross totals.
  ///
  /// Returns the final [totalNet], [totalGross], and an audit-trail list of
  /// [CalculationStep]s.
  static ({double totalNet, double totalGross, List<CalculationStep> billSteps})
      _applyBillDiscounts({
    required List<BillDiscount> billDiscounts,
    required double subtotalNet,
    required double subtotalGross,
    required double globalTaxRate,
  }) {
    final rate = globalTaxRate / 100;
    var runningNet = subtotalNet;
    var runningGross = subtotalGross;
    final steps = <CalculationStep>[];

    final activeDiscounts = billDiscounts.where((d) => d.value > 0).toList();
    if (activeDiscounts.isEmpty) {
      return (
        totalNet: runningNet,
        totalGross: runningGross,
        billSteps: steps,
      );
    }

    steps.add(const CalculationStep.header('BILL-LEVEL DISCOUNTS'));

    for (final discount in activeDiscounts) {
      switch (discount.applyOn) {
        case DiscountApplyOn.gross:
          (runningNet, runningGross) = _applyBillDiscountOnGross(
            discount: discount,
            rate: rate,
            globalTaxRate: globalTaxRate,
            runningGross: runningGross,
            steps: steps,
          );

        case DiscountApplyOn.net:
          (runningNet, runningGross) = _applyBillDiscountOnNet(
            discount: discount,
            rate: rate,
            globalTaxRate: globalTaxRate,
            runningNet: runningNet,
            steps: steps,
          );
      }
    }

    steps.add(CalculationStep(
      label: 'Total bill discount saved',
      formula: '${_fmt(subtotalGross)} − ${_fmt(runningGross)}',
      value: subtotalGross - runningGross,
      highlight: StepHighlight.discount,
    ));

    return (
      totalNet: runningNet,
      totalGross: runningGross,
      billSteps: steps,
    );
  }

  /// Applies a bill discount to the gross total.
  ///
  /// ```
  /// newGross = runningGross − discountAmount
  /// newNet   = newGross / (1 + rate)
  /// ```
  static (double newNet, double newGross) _applyBillDiscountOnGross({
    required BillDiscount discount,
    required double rate,
    required double globalTaxRate,
    required double runningGross,
    required List<CalculationStep> steps,
  }) {
    final discountAmount =
        _discountAmount(discount.type, discount.value, runningGross);

    if (discount.type == DiscountType.percentage) {
      steps.add(CalculationStep(
        label: 'Discount % of gross total',
        formula: '${_fmt(discount.value)}% of ${_fmt(runningGross)}',
        value: discountAmount,
        highlight: StepHighlight.discount,
      ));
    }
    steps.add(CalculationStep(
      label: 'Discount amount = ${_fmt(runningGross)} × ${_fmt(discount.value / 100)}',
      formula: '= ${_fmt(discountAmount)}',
      value: discountAmount,
      highlight: StepHighlight.discount,
    ));

    final newGross = runningGross - discountAmount;
    final newNet = newGross / (1 + rate);

    steps.add(CalculationStep(
      label: 'New gross = ${_fmt(runningGross)} − ${_fmt(discountAmount)}',
      formula: '= ${_fmt(newGross)}',
      value: newGross,
    ));

    return (newNet, newGross);
  }

  /// Applies a bill discount to the net total, then re-applies tax.
  ///
  /// Re-applying tax (rather than simply subtracting from gross) ensures the
  /// tax amount is correctly recalculated on the reduced taxable base:
  /// ```
  /// newNet   = runningNet − discountAmount
  /// newGross = newNet × (1 + rate)
  /// ```
  static (double newNet, double newGross) _applyBillDiscountOnNet({
    required BillDiscount discount,
    required double rate,
    required double globalTaxRate,
    required double runningNet,
    required List<CalculationStep> steps,
  }) {
    final discountAmount =
        _discountAmount(discount.type, discount.value, runningNet);

    if (discount.type == DiscountType.percentage) {
      steps.add(CalculationStep(
        label: 'Discount % of net total',
        formula: '${_fmt(discount.value)}% of ${_fmt(runningNet)}',
        value: discountAmount,
        highlight: StepHighlight.discount,
      ));
    }
    steps.add(CalculationStep(
      label: 'Discount amount = ${_fmt(runningNet)} × ${_fmt(discount.value / 100)}',
      formula: '= ${_fmt(discountAmount)}',
      value: discountAmount,
      highlight: StepHighlight.discount,
    ));

    final newNet = runningNet - discountAmount;
    final newGross = newNet * (1 + rate);

    steps
      ..add(CalculationStep(
        label: 'New net = ${_fmt(runningNet)} − ${_fmt(discountAmount)}',
        formula: '= ${_fmt(newNet)}',
        value: newNet,
      ))
      ..add(CalculationStep(
        label: 'New gross = new net × (1 + ${_fmt(globalTaxRate)}%)',
        formula: '${_fmt(newNet)} × ${_fmt(1 + rate)} = ${_fmt(newGross)}',
        value: newGross,
        highlight: StepHighlight.tax,
      ));

    return (newNet, newGross);
  }

  // ── Shared helpers ───────────────────────────────────────────────────────

  /// Formats a [double] to exactly 2 decimal places.
  static String _fmt(double v) => v.toStringAsFixed(2);

  /// Calculates the actual discount amount given a [type], a percentage/fixed
  /// [value], and the [base] it applies to.
  ///
  /// Fixed amounts are clamped to [base] so the result is never negative.
  static double _discountAmount(
    DiscountType type,
    double value,
    double base,
  ) =>
      type == DiscountType.percentage
          ? base * (value / 100)
          : value.clamp(0.0, base);
}
