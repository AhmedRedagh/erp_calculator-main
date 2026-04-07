import 'package:meta/meta.dart';

import '../enums/discount_apply_on.dart';
import '../enums/discount_type.dart';
import '../enums/tax_mode.dart';

/// An immutable representation of a single product or service on a bill.
///
/// ### Example
/// ```dart
/// const item = LineItem(
///   id: 'SKU-001',
///   name: 'Widget Pro',
///   unitPrice: 50.00,
///   qty: 3,
///   taxMode: TaxMode.exclusive,
///   taxRate: 15,
///   discountValue: 10,
///   discountType: DiscountType.percentage,
///   discountApplyOn: DiscountApplyOn.net,
/// );
/// ```
@immutable
class LineItem {
  /// Unique identifier for this line (e.g. SKU, UUID).
  final String id;

  /// Human-readable product or service name.
  final String name;

  /// Price per single unit before any discount, in the bill's currency.
  /// Must be >= 0.
  final double unitPrice;

  /// Number of units ordered. Must be >= 1.
  final int qty;

  /// Describes how tax relates to [unitPrice].
  final TaxMode taxMode;

  /// Per-item tax rate percentage.
  ///
  /// This value is ignored when [taxMode] is [TaxMode.none].
  final double taxRate;

  /// Discount value to apply to this line.
  /// Interpreted as a percentage when [discountType] is [DiscountType.percentage],
  /// or as a fixed amount otherwise. `null` / `0` means no discount.
  final double? discountValue;

  /// Whether [discountValue] is a percentage or a fixed amount.
  final DiscountType discountType;

  /// Whether the discount is applied to the gross or net price.
  final DiscountApplyOn discountApplyOn;

  const LineItem({
    required this.id,
    required this.name,
    this.unitPrice = 0,
    this.qty = 1,
    this.taxMode = TaxMode.exclusive,
    this.taxRate = 0,
    this.discountValue,
    this.discountType = DiscountType.percentage,
    this.discountApplyOn = DiscountApplyOn.gross,
  })  : assert(unitPrice >= 0, 'unitPrice must be >= 0'),
        assert(qty >= 1, 'qty must be >= 1'),
        assert(taxRate >= 0, 'taxRate must be >= 0');

  /// Returns a copy of this [LineItem] with the given fields replaced.
  ///
  /// Set [clearDiscount] to `true` to remove the discount entirely
  /// (sets [discountValue] to `null`, regardless of the [discountValue] arg).
  LineItem copyWith({
    String? id,
    String? name,
    double? unitPrice,
    int? qty,
    TaxMode? taxMode,
    double? taxRate,
    double? discountValue,
    bool clearDiscount = false,
    DiscountType? discountType,
    DiscountApplyOn? discountApplyOn,
  }) {
    return LineItem(
      id: id ?? this.id,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      qty: qty ?? this.qty,
      taxMode: taxMode ?? this.taxMode,
      taxRate: taxRate ?? this.taxRate,
      discountValue:
          clearDiscount ? null : (discountValue ?? this.discountValue),
      discountType: discountType ?? this.discountType,
      discountApplyOn: discountApplyOn ?? this.discountApplyOn,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          unitPrice == other.unitPrice &&
          qty == other.qty &&
          taxMode == other.taxMode &&
          taxRate == other.taxRate &&
          discountValue == other.discountValue &&
          discountType == other.discountType &&
          discountApplyOn == other.discountApplyOn;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        unitPrice,
        qty,
        taxMode,
        taxRate,
        discountValue,
        discountType,
        discountApplyOn,
      );

  @override
  String toString() => 'LineItem('
      'id: $id, '
      'name: $name, '
      'unitPrice: $unitPrice, '
      'qty: $qty, '
      'taxMode: $taxMode, '
      'taxRate: $taxRate'
      ')';
}
