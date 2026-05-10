# erp_calculator

`erp_calculator` is a pure Dart billing engine for ERP, POS, and invoicing flows.
It calculates per-line and bill-level totals with support for:

- `TaxMode.none`, `TaxMode.exclusive`, and `TaxMode.inclusive`
- Item discounts as percentage or fixed amounts
- Bill discounts applied on net or gross totals
- A step-by-step audit trail for explaining every calculation

## Installation

```yaml
dependencies:
  erp_calculator: ^1.0.0
```

## Quick start

```dart
import 'package:erp_calculator/erp_calculator.dart';

void main() {
  final result = BillingEngine.calculate(
    items: const [
      LineItem(
        id: 'sku-1',
        name: 'Product A',
        unitPrice: 100,
        qty: 2,
        taxMode: TaxMode.exclusive,
        taxRate: 15,
        discountValue: 10,
        discountType: DiscountType.percentage,
        discountApplyOn: DiscountApplyOn.gross,
      ),
    ],
    billDiscounts: const [
      BillDiscount(
        id: 'promo-5',
        value: 5,
        type: DiscountType.percentage,
        applyOn: DiscountApplyOn.gross,
      ),
    ],
  );

  print(result.subtotalGross);
  print(result.totalGross);
  print(result.totalSaved);
}
```

## When to use it

Use this package when you need deterministic pricing logic that can be reused in:

- ERP and inventory systems
- POS and checkout flows
- Invoice builders
- Quotation tools

Because the engine is stateless and side-effect free, it is safe to call from UI code, services, isolates, and tests.

## Example

See [example/main.dart](example/main.dart) for a runnable usage example.

