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

  /// Tax-included price before the item discount.
  ///
  /// Equals [basePrice] for inclusive and no-tax lines, and
  /// `basePrice × (1 + taxRate)` for exclusive lines.
  final double originalGross;

  /// Pre-tax amount after discounts are applied.
  final double net;

  /// Tax portion of the final price.
  final double tax;

  /// Amount the customer actually pays: `net + tax`.
  final double gross;

  /// Discount amount taken from the configured apply-on basis (always ≥ 0).
  ///
  /// When the discount applies on `net`, this is a pre-tax amount and the
  /// customer saves more than this, because tax is re-applied on the reduced
  /// net. Use [discountImpactOnGross] for what the customer actually saves.
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
    required this.originalGross,
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

  /// Reduction in the customer-paid amount caused by the item discount:
  /// `originalGross - gross`.
  double get discountImpactOnGross => originalGross - gross;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineItemResult &&
          runtimeType == other.runtimeType &&
          basePrice == other.basePrice &&
          originalGross == other.originalGross &&
          net == other.net &&
          tax == other.tax &&
          gross == other.gross &&
          discountAmount == other.discountAmount &&
          displayDiscountPercentage == other.displayDiscountPercentage;

  @override
  int get hashCode =>
      Object.hash(
        basePrice,
        originalGross,
        net,
        tax,
        gross,
        discountAmount,
        displayDiscountPercentage,
      );

  @override
  String toString() => 'LineItemResult('
      'originalGross: $originalGross, '
      'net: $net, '
      'tax: $tax, '
      'gross: $gross, '
      'discountAmount: $discountAmount, '
      'displayDiscountPercentage: $displayDiscountPercentage'
      ')';
}
