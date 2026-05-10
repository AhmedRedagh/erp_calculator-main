/// ERP Calculator - Pure Dart billing calculation engine.
///
/// A stateless, side-effect-free engine for computing line-item and bill-level
/// tax/discount totals. Safe to call on every keystroke or in any isolate.
///
/// ## Quick start
///
/// ```dart
/// import 'package:erp_calculator/erp_calculator.dart';
///
/// final result = BillingEngine.calculate(
///   items: [
///     LineItem(
///       id: '1',
///       name: 'Product A',
///       unitPrice: 100,
///       qty: 2,
///       taxMode: TaxMode.exclusive,
///       taxRate: 15,
///       discountValue: 10,
///       discountType: DiscountType.percentage,
///       discountApplyOn: DiscountApplyOn.gross,
///     ),
///   ],
///   billDiscounts: [],
/// );
///
/// print(result.totalGross); // 207.00
/// ```
///
/// ## Discount logic cheat-sheet
///
/// | applyOn | behaviour |
/// |---------|-----------|
/// | `gross` | Discount is taken from the tax-included price. Net is back-calculated. |
/// | `net`   | Discount is taken from the pre-tax price. Tax is re-applied on the reduced net. |
library erp_calculator;

export 'src/engine/billing_engine.dart';
export 'src/enums/discount_apply_on.dart';
export 'src/enums/discount_type.dart';
export 'src/enums/tax_mode.dart';
export 'src/models/bill_discount.dart';
export 'src/models/bill_result.dart';
export 'src/models/calculation_step.dart';
export 'src/models/line_item.dart';
export 'src/models/line_item_result.dart';
