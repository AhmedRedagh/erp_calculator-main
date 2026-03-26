import 'package:meta/meta.dart';

import '../enums/discount_apply_on.dart';
import '../enums/discount_type.dart';

/// An immutable bill-level discount applied **after** all line items are summed.
///
/// Multiple [BillDiscount]s are applied sequentially; each one operates on the
/// running total left by the previous one.
///
/// ### Example — 5 % off the gross total
/// ```dart
/// const discount = BillDiscount(
///   id: 'PROMO-5',
///   value: 5,
///   type: DiscountType.percentage,
///   applyOn: DiscountApplyOn.gross,
/// );
/// ```
@immutable
class BillDiscount {
  /// Unique identifier for this discount (e.g. promo code, UUID).
  final String id;

  /// Discount value. Interpreted as a percentage or a fixed amount depending
  /// on [type]. Must be > 0 to have any effect.
  final double value;

  /// Whether [value] is a percentage or a fixed currency amount.
  final DiscountType type;

  /// The price base the discount is applied against.
  ///
  /// - [DiscountApplyOn.gross]: `finalGross = totalGross − discountAmount`
  /// - [DiscountApplyOn.net]: `finalNet = totalNet − discountAmount`,
  ///   then tax is **re-applied** → `finalGross = finalNet × (1 + rate)`
  final DiscountApplyOn applyOn;

  const BillDiscount({
    required this.id,
    required this.value,
    this.type = DiscountType.percentage,
    this.applyOn = DiscountApplyOn.gross,
  }) : assert(value >= 0, 'value must be ≥ 0');

  /// Returns a copy of this [BillDiscount] with the given fields replaced.
  BillDiscount copyWith({
    String? id,
    double? value,
    DiscountType? type,
    DiscountApplyOn? applyOn,
  }) {
    return BillDiscount(
      id: id ?? this.id,
      value: value ?? this.value,
      type: type ?? this.type,
      applyOn: applyOn ?? this.applyOn,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillDiscount &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          value == other.value &&
          type == other.type &&
          applyOn == other.applyOn;

  @override
  int get hashCode => Object.hash(id, value, type, applyOn);

  @override
  String toString() =>
      'BillDiscount(id: $id, value: $value, type: $type, applyOn: $applyOn)';
}
