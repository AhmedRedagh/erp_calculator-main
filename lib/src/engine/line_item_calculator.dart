// ignore_for_file: avoid_classes_with_only_static_members

import '../enums/discount_apply_on.dart';
import '../enums/discount_type.dart';
import '../enums/tax_mode.dart';
import '../models/calculation_step.dart';
import '../models/line_item.dart';
import '../models/line_item_result.dart';

/// Internal helper that computes the [LineItemResult] for a single [LineItem].
abstract final class LineItemCalculator {
  /// Calculates a single [LineItem] and returns its [LineItemResult].
  static LineItemResult calculate(LineItem item) {
    final taxRate = item.taxMode == TaxMode.none ? 0.0 : item.taxRate;
    final steps = <CalculationStep>[];

    final basePrice = _computeBasePrice(item, steps);
    var (:net, :tax, :gross) = _computeTax(item, basePrice, taxRate, steps);
    var discountAmount = 0.0;

    final dv = item.discountValue ?? 0;
    if (dv > 0) {
      final discountResult = _applyItemDiscount(
        item: item,
        dv: dv,
        taxRate: taxRate,
        net: net,
        gross: gross,
        steps: steps,
      );
      net = discountResult.net;
      tax = discountResult.tax;
      gross = discountResult.gross;
      discountAmount = discountResult.discountAmount;
    }

    _addResultSummary(taxRate, net, tax, gross, discountAmount, steps);

    return LineItemResult(
      basePrice: basePrice,
      net: net,
      tax: tax,
      gross: gross,
      discountAmount: discountAmount,
      steps: steps,
    );
  }

  static double _computeBasePrice(
    LineItem item,
    List<CalculationStep> steps,
  ) {
    final base = item.unitPrice * item.qty;

    steps
      ..add(const CalculationStep.header('STEP 1 - BASE PRICE'))
      ..add(
        CalculationStep(
          label: 'Unit price x qty',
          formula: '${_fmt(item.unitPrice)} x ${item.qty} = ${_fmt(base)}',
          value: base,
        ),
      );

    return base;
  }

  static ({double net, double tax, double gross}) _computeTax(
    LineItem item,
    double base,
    double taxRate,
    List<CalculationStep> steps,
  ) {
    final rate = taxRate / 100;

    return switch (item.taxMode) {
      TaxMode.none => _taxNone(base, steps),
      TaxMode.exclusive => _taxExclusive(base, rate, taxRate, steps),
      TaxMode.inclusive => _taxInclusive(base, rate, taxRate, steps),
    };
  }

  static ({double net, double tax, double gross}) _taxNone(
    double base,
    List<CalculationStep> steps,
  ) {
    steps
      ..add(const CalculationStep.header('STEP 2 - NO TAX'))
      ..add(
        CalculationStep(
          label: 'Net = Gross = base (no tax)',
          formula: _fmt(base),
          value: base,
        ),
      );
    return (net: base, tax: 0.0, gross: base);
  }

  static ({double net, double tax, double gross}) _taxExclusive(
    double base,
    double rate,
    double taxRate,
    List<CalculationStep> steps,
  ) {
    final net = base;
    final tax = net * rate;
    final gross = net + tax;

    steps
      ..add(
        const CalculationStep.header('STEP 2 - TAX EXCLUSIVE (ADDED ON TOP)'),
      )
      ..add(
        CalculationStep(
          label: 'Net = price as-is',
          formula: _fmt(net),
          value: net,
        ),
      )
      ..add(
        CalculationStep(
          label: 'Tax = Net x ${_fmt(taxRate)}%',
          formula: '${_fmt(net)} x ${_fmt(rate)} = ${_fmt(tax)}',
          value: tax,
          highlight: StepHighlight.tax,
        ),
      )
      ..add(
        CalculationStep(
          label: 'Gross = Net + Tax',
          formula: '${_fmt(net)} + ${_fmt(tax)} = ${_fmt(gross)}',
          value: gross,
        ),
      );

    return (net: net, tax: tax, gross: gross);
  }

  static ({double net, double tax, double gross}) _taxInclusive(
    double base,
    double rate,
    double taxRate,
    List<CalculationStep> steps,
  ) {
    final gross = base;
    final net = gross / (1 + rate);
    final tax = gross - net;

    steps
      ..add(const CalculationStep.header('STEP 2 - TAX INCLUSIVE (EXTRACTED)'))
      ..add(
        CalculationStep(
          label: 'Gross = price as-is',
          formula: _fmt(gross),
          value: gross,
        ),
      )
      ..add(
        CalculationStep(
          label: 'Net = Gross / (1 + ${_fmt(taxRate)}%)',
          formula: '${_fmt(gross)} / ${_fmt(1 + rate)} = ${_fmt(net)}',
          value: net,
        ),
      )
      ..add(
        CalculationStep(
          label: 'Tax = Gross - Net',
          formula: '${_fmt(gross)} - ${_fmt(net)} = ${_fmt(tax)}',
          value: tax,
          highlight: StepHighlight.tax,
        ),
      );

    return (net: net, tax: tax, gross: gross);
  }

  static ({double net, double tax, double gross, double discountAmount})
      _applyItemDiscount({
    required LineItem item,
    required double dv,
    required double taxRate,
    required double net,
    required double gross,
    required List<CalculationStep> steps,
  }) =>
          switch (item.discountApplyOn) {
            DiscountApplyOn.gross => _discountOnGross(
                item: item,
                dv: dv,
                taxRate: taxRate,
                gross: gross,
                steps: steps,
              ),
            DiscountApplyOn.net => _discountOnNet(
                item: item,
                dv: dv,
                taxRate: taxRate,
                net: net,
                steps: steps,
              ),
          };

  static ({double net, double tax, double gross, double discountAmount})
      _discountOnGross({
    required LineItem item,
    required double dv,
    required double taxRate,
    required double gross,
    required List<CalculationStep> steps,
  }) {
    final rate = taxRate / 100;
    final discountAmount = _discountAmount(item.discountType, dv, gross);

    final headerLabel = item.discountType == DiscountType.percentage
        ? 'STEP 3 - ${_fmt(dv)}% DISCOUNT ON GROSS (TAX-INCLUDED PRICE)'
        : 'STEP 3 - FIXED DISCOUNT ON GROSS (TAX-INCLUDED PRICE)';
    steps.add(CalculationStep.header(headerLabel));

    if (item.discountType == DiscountType.percentage) {
      steps.add(
        CalculationStep(
          label: 'Discount % of gross',
          formula: '${_fmt(dv)}% of ${_fmt(gross)}',
          value: discountAmount,
          highlight: StepHighlight.discount,
        ),
      );
    }
    steps.add(
      CalculationStep(
        label: 'Discount amount',
        formula: _fmt(discountAmount),
        value: discountAmount,
        highlight: StepHighlight.discount,
      ),
    );

    final newGross = gross - discountAmount;
    final newNet = newGross / (1 + rate);
    final newTax = newGross - newNet;

    steps
      ..add(
        CalculationStep(
          label: 'New gross = old gross - discount',
          formula:
              '${_fmt(gross)} - ${_fmt(discountAmount)} = ${_fmt(newGross)}',
          value: newGross,
        ),
      )
      ..add(
        CalculationStep(
          label: 'New net = New gross / (1 + ${_fmt(taxRate)}%)',
          formula: '${_fmt(newGross)} / ${_fmt(1 + rate)} = ${_fmt(newNet)}',
          value: newNet,
        ),
      )
      ..add(
        CalculationStep(
          label: 'New tax = New gross - New net',
          formula: '${_fmt(newGross)} - ${_fmt(newNet)} = ${_fmt(newTax)}',
          value: newTax,
          highlight: StepHighlight.tax,
        ),
      );

    return (
      net: newNet,
      tax: newTax,
      gross: newGross,
      discountAmount: discountAmount,
    );
  }

  static ({double net, double tax, double gross, double discountAmount})
      _discountOnNet({
    required LineItem item,
    required double dv,
    required double taxRate,
    required double net,
    required List<CalculationStep> steps,
  }) {
    final rate = taxRate / 100;
    final discountAmount = _discountAmount(item.discountType, dv, net);

    final headerLabel = item.discountType == DiscountType.percentage
        ? 'STEP 3 - ${_fmt(dv)}% DISCOUNT ON NET (PRE-TAX PRICE)'
        : 'STEP 3 - FIXED DISCOUNT ON NET (PRE-TAX PRICE)';
    steps.add(CalculationStep.header(headerLabel));

    if (item.discountType == DiscountType.percentage) {
      steps.add(
        CalculationStep(
          label: 'Discount % of net',
          formula: '${_fmt(dv)}% of ${_fmt(net)}',
          value: discountAmount,
          highlight: StepHighlight.discount,
        ),
      );
    }
    steps.add(
      CalculationStep(
        label: 'Discount amount',
        formula: _fmt(discountAmount),
        value: discountAmount,
        highlight: StepHighlight.discount,
      ),
    );

    final newNet = net - discountAmount;
    final newTax = newNet * rate;
    final newGross = newNet + newTax;

    steps
      ..add(
        CalculationStep(
          label: 'New net = old net - discount',
          formula: '${_fmt(net)} - ${_fmt(discountAmount)} = ${_fmt(newNet)}',
          value: newNet,
        ),
      )
      ..add(
        CalculationStep(
          label: 'New tax = New net x ${_fmt(taxRate)}%',
          formula: '${_fmt(newNet)} x ${_fmt(rate)} = ${_fmt(newTax)}',
          value: newTax,
          highlight: StepHighlight.tax,
        ),
      )
      ..add(
        CalculationStep(
          label: 'New gross = New net + New tax',
          formula: '${_fmt(newNet)} + ${_fmt(newTax)} = ${_fmt(newGross)}',
          value: newGross,
        ),
      );

    return (
      net: newNet,
      tax: newTax,
      gross: newGross,
      discountAmount: discountAmount,
    );
  }

  static void _addResultSummary(
    double taxRate,
    double net,
    double tax,
    double gross,
    double discountAmount,
    List<CalculationStep> steps,
  ) {
    steps
      ..add(const CalculationStep.header('RESULT FOR THIS LINE'))
      ..add(
        CalculationStep(
          label: 'Net',
          formula: _fmt(net),
          value: net,
        ),
      )
      ..add(
        CalculationStep(
          label: 'Tax (${_fmt(taxRate)}%)',
          formula: _fmt(tax),
          value: tax,
          highlight: StepHighlight.tax,
        ),
      )
      ..add(
        CalculationStep(
          label: 'Gross (what customer pays)',
          formula: _fmt(gross),
          value: gross,
          highlight: StepHighlight.result,
        ),
      );

    if (discountAmount > 0) {
      steps.add(
        CalculationStep(
          label: 'Saved by discount',
          formula: _fmt(discountAmount),
          value: discountAmount,
          highlight: StepHighlight.discount,
        ),
      );
    }
  }

  static String _fmt(double v) => v.toStringAsFixed(2);

  static double _discountAmount(
    DiscountType type,
    double value,
    double base,
  ) =>
      type == DiscountType.percentage
          ? base * (value / 100)
          : value.clamp(0.0, base);
}
