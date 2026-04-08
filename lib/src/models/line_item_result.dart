import 'package:meta/meta.dart';

import 'calculation_step.dart';

/// The immutable computed result for a single [LineItem].
///
/// All monetary values are in the bill's currency and rounded to 2 decimal
/// places by [BillingEngine].
@immutable
class LineItemResult {
  /// Raw price before any tax or discount: `unitPrice × qty`.
  final double basePrice;

  /// Pre-tax amount after discounts are applied.
  final double net;

  /// Tax portion of the final price.
  final double tax;

  /// Amount the customer actually pays: `net + tax`.
  final double gross;

  /// Total discount saved on this line (always ≥ 0).
  final double discountAmount;

  /// Discount percentage intended for display in UI.
  ///
  /// If discount type is percentage, this is the entered percentage.
  /// If discount type is fixed amount, this is derived from
  /// `discountAmount / basePrice * 100`.
  final double displayDiscountPercentage;

  /// Step-by-step audit trail that explains how [net], [tax], and [gross]
  /// were derived. Suitable for display in a calculation breakdown UI.
  final List<CalculationStep> steps;

  const LineItemResult({
    required this.basePrice,
    required this.net,
    required this.tax,
    required this.gross,
    required this.discountAmount,
    required this.displayDiscountPercentage,
    required this.steps,
  });

  /// Unit price x qty, before tax.
  double get originalPriceWithoutTax => basePrice;

  /// Price without tax after discount, for UI display.
  double get discountedPriceWithoutTax => (basePrice - discountAmount).clamp(
        0.0,
        basePrice,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineItemResult &&
          runtimeType == other.runtimeType &&
          basePrice == other.basePrice &&
          net == other.net &&
          tax == other.tax &&
          gross == other.gross &&
          discountAmount == other.discountAmount &&
          displayDiscountPercentage == other.displayDiscountPercentage;

  @override
  int get hashCode =>
      Object.hash(
        basePrice,
        net,
        tax,
        gross,
        discountAmount,
        displayDiscountPercentage,
      );

  @override
  String toString() => 'LineItemResult('
      'net: $net, '
      'tax: $tax, '
      'gross: $gross, '
      'discountAmount: $discountAmount, '
      'displayDiscountPercentage: $displayDiscountPercentage'
      ')';
}
