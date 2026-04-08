import '../enums/discount_apply_on.dart';
import '../enums/discount_type.dart';
import '../enums/tax_mode.dart';
import '../models/bill_discount.dart';
import '../models/bill_result.dart';
import '../models/calculation_step.dart';
import '../models/line_item.dart';
import '../models/line_item_result.dart';
import 'line_item_calculator.dart';

/// The core ERP billing engine.
abstract final class BillingEngine {
  /// Calculates the full bill and returns an immutable [BillResult].
  static BillResult calculate({
    required List<LineItem> items,
    required List<BillDiscount> billDiscounts,
  }) {
    _validate(items);

    final lineResults = [
      for (final item in items) LineItemCalculator.calculate(item),
    ];

    final subtotalNet = lineResults.fold(0.0, (sum, r) => sum + r.net);
    final subtotalTax = lineResults.fold(0.0, (sum, r) => sum + r.tax);
    final subtotalGross = lineResults.fold(0.0, (sum, r) => sum + r.gross);
    final itemDiscountSavings =
        lineResults.fold(0.0, (sum, r) => sum + r.discountAmount);

    final (:totalNet, :totalGross, :billSteps) = _applyBillDiscounts(
      items: items,
      lineResults: lineResults,
      billDiscounts: billDiscounts,
    );

    final totalTax = totalGross - totalNet;
    final billDiscountAmount = subtotalGross - totalGross;
    final billDiscountDisplayPercentage = _billDiscountDisplayPercentage(
      billDiscounts: billDiscounts,
      subtotalNet: subtotalNet,
    );

    return BillResult(
      lineResults: lineResults,
      subtotalNet: subtotalNet,
      subtotalTax: subtotalTax,
      subtotalGross: subtotalGross,
      billDiscountAmount: billDiscountAmount,
      billDiscountDisplayPercentage: billDiscountDisplayPercentage,
      totalNet: totalNet,
      totalTax: totalTax,
      totalGross: totalGross,
      totalSaved: itemDiscountSavings + billDiscountAmount,
      billSteps: billSteps,
    );
  }

  static void _validate(List<LineItem> items) {
    if (items.isEmpty) {
      throw ArgumentError.value(
        items,
        'items',
        'Must contain at least one LineItem.',
      );
    }
  }

  static ({double totalNet, double totalGross, List<CalculationStep> billSteps})
      _applyBillDiscounts({
    required List<LineItem> items,
    required List<LineItemResult> lineResults,
    required List<BillDiscount> billDiscounts,
  }) {
    final runningLines = [
      for (var i = 0; i < items.length; i++)
        _RunningLine.from(items[i], lineResults[i]),
    ];
    final steps = <CalculationStep>[];

    final activeDiscounts = billDiscounts.where((d) => d.value > 0).toList();
    if (activeDiscounts.isEmpty) {
      return (
        totalNet: runningLines.fold(0.0, (sum, line) => sum + line.net),
        totalGross: runningLines.fold(0.0, (sum, line) => sum + line.gross),
        billSteps: steps,
      );
    }

    steps.add(const CalculationStep.header('BILL-LEVEL DISCOUNTS'));

    for (final discount in activeDiscounts) {
      final runningNet = runningLines.fold(0.0, (sum, line) => sum + line.net);
      final runningGross =
          runningLines.fold(0.0, (sum, line) => sum + line.gross);

      switch (discount.applyOn) {
        case DiscountApplyOn.gross:
          _applyBillDiscountOnGross(
            discount: discount,
            runningLines: runningLines,
            runningGross: runningGross,
            steps: steps,
          );
        case DiscountApplyOn.net:
          _applyBillDiscountOnNet(
            discount: discount,
            runningLines: runningLines,
            runningNet: runningNet,
            steps: steps,
          );
      }
    }

    final finalNet = runningLines.fold(0.0, (sum, line) => sum + line.net);
    final finalGross = runningLines.fold(0.0, (sum, line) => sum + line.gross);
    final subtotalGross = lineResults.fold(0.0, (sum, r) => sum + r.gross);

    steps.add(
      CalculationStep(
        label: 'Total bill discount saved',
        formula: '${_fmt(subtotalGross)} - ${_fmt(finalGross)}',
        value: subtotalGross - finalGross,
        highlight: StepHighlight.discount,
      ),
    );

    return (
      totalNet: finalNet,
      totalGross: finalGross,
      billSteps: steps,
    );
  }

  static void _applyBillDiscountOnGross({
    required BillDiscount discount,
    required List<_RunningLine> runningLines,
    required double runningGross,
    required List<CalculationStep> steps,
  }) {
    final discountAmount =
        _discountAmount(discount.type, discount.value, runningGross);

    if (discount.type == DiscountType.percentage) {
      steps.add(
        CalculationStep(
          label: 'Discount % of gross total',
          formula: '${_fmt(discount.value)}% of ${_fmt(runningGross)}',
          value: discountAmount,
          highlight: StepHighlight.discount,
        ),
      );
    }
    steps.add(
      CalculationStep(
        label: 'Discount amount on gross',
        formula: _fmt(discountAmount),
        value: discountAmount,
        highlight: StepHighlight.discount,
      ),
    );

    _allocateAcrossLines(
      runningLines: runningLines,
      totalBase: runningGross,
      totalDiscount: discountAmount,
      basis: (line) => line.gross,
      apply: (line, share) => line.applyGrossDiscount(share),
    );

    final newGross = runningLines.fold(0.0, (sum, line) => sum + line.gross);
    final newNet = runningLines.fold(0.0, (sum, line) => sum + line.net);

    steps
      ..add(
        CalculationStep(
          label: 'New gross total',
          formula:
              '${_fmt(runningGross)} - ${_fmt(discountAmount)} = ${_fmt(newGross)}',
          value: newGross,
        ),
      )
      ..add(
        CalculationStep(
          label: 'New net total',
          formula: _fmt(newNet),
          value: newNet,
        ),
      );
  }

  static void _applyBillDiscountOnNet({
    required BillDiscount discount,
    required List<_RunningLine> runningLines,
    required double runningNet,
    required List<CalculationStep> steps,
  }) {
    final discountAmount =
        _discountAmount(discount.type, discount.value, runningNet);

    if (discount.type == DiscountType.percentage) {
      steps.add(
        CalculationStep(
          label: 'Discount % of net total',
          formula: '${_fmt(discount.value)}% of ${_fmt(runningNet)}',
          value: discountAmount,
          highlight: StepHighlight.discount,
        ),
      );
    }
    steps.add(
      CalculationStep(
        label: 'Discount amount on net',
        formula: _fmt(discountAmount),
        value: discountAmount,
        highlight: StepHighlight.discount,
      ),
    );

    _allocateAcrossLines(
      runningLines: runningLines,
      totalBase: runningNet,
      totalDiscount: discountAmount,
      basis: (line) => line.net,
      apply: (line, share) => line.applyNetDiscount(share),
    );

    final newNet = runningLines.fold(0.0, (sum, line) => sum + line.net);
    final newGross = runningLines.fold(0.0, (sum, line) => sum + line.gross);

    steps
      ..add(
        CalculationStep(
          label: 'New net total',
          formula:
              '${_fmt(runningNet)} - ${_fmt(discountAmount)} = ${_fmt(newNet)}',
          value: newNet,
        ),
      )
      ..add(
        CalculationStep(
          label: 'New gross total after recalculating line taxes',
          formula: _fmt(newGross),
          value: newGross,
          highlight: StepHighlight.tax,
        ),
      );
  }

  static void _allocateAcrossLines({
    required List<_RunningLine> runningLines,
    required double totalBase,
    required double totalDiscount,
    required double Function(_RunningLine line) basis,
    required void Function(_RunningLine line, double share) apply,
  }) {
    if (totalBase <= 0 || totalDiscount <= 0) {
      return;
    }

    var remainingDiscount = totalDiscount;
    final eligibleLines =
        runningLines.where((line) => basis(line) > 0).toList();

    for (var i = 0; i < eligibleLines.length; i++) {
      final line = eligibleLines[i];
      final share = i == eligibleLines.length - 1
          ? remainingDiscount
          : totalDiscount * (basis(line) / totalBase);
      final clampedShare = share.clamp(0.0, basis(line));
      apply(line, clampedShare);
      remainingDiscount -= clampedShare;
    }
  }

  static String _fmt(double v) => v.toStringAsFixed(2);

  static double _billDiscountDisplayPercentage({
    required List<BillDiscount> billDiscounts,
    required double subtotalNet,
  }) {
    if (subtotalNet <= 0) {
      return 0.0;
    }

    final active = billDiscounts.where((d) => d.value > 0).toList();
    if (active.isEmpty) {
      return 0.0;
    }
    if (active.length == 1 && active.first.type == DiscountType.percentage) {
      return active.first.value;
    }

    var runningNet = subtotalNet;
    var totalDiscountOnNet = 0.0;

    for (final discount in active) {
      final discountAmount = _discountAmount(
        discount.type,
        discount.value,
        runningNet,
      );
      totalDiscountOnNet += discountAmount;
      runningNet = (runningNet - discountAmount).clamp(0.0, runningNet);
    }

    return (totalDiscountOnNet / subtotalNet) * 100;
  }

  static double _discountAmount(
    DiscountType type,
    double value,
    double base,
  ) =>
      type == DiscountType.percentage
          ? base * (value / 100)
          : value.clamp(0.0, base);
}

final class _RunningLine {
  _RunningLine({
    required this.taxMode,
    required this.taxRate,
    required this.net,
    required this.tax,
    required this.gross,
  });

  factory _RunningLine.from(LineItem item, LineItemResult result) =>
      _RunningLine(
        taxMode: item.taxMode,
        taxRate: item.taxMode == TaxMode.none ? 0.0 : item.taxRate,
        net: result.net,
        tax: result.tax,
        gross: result.gross,
      );

  final TaxMode taxMode;
  final double taxRate;
  double net;
  double tax;
  double gross;

  void applyGrossDiscount(double discountShare) {
    final newGross = (gross - discountShare).clamp(0.0, gross);
    _recomputeFromGross(newGross);
  }

  void applyNetDiscount(double discountShare) {
    final newNet = (net - discountShare).clamp(0.0, net);
    _recomputeFromNet(newNet);
  }

  void _recomputeFromGross(double newGross) {
    if (taxMode == TaxMode.none || taxRate == 0) {
      gross = newGross;
      net = newGross;
      tax = 0.0;
      return;
    }

    gross = newGross;
    net = gross / (1 + taxRate / 100);
    tax = gross - net;
  }

  void _recomputeFromNet(double newNet) {
    if (taxMode == TaxMode.none || taxRate == 0) {
      net = newNet;
      gross = newNet;
      tax = 0.0;
      return;
    }

    net = newNet;
    tax = net * (taxRate / 100);
    gross = net + tax;
  }
}
