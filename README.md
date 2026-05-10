# erp_calculator

`erp_calculator` is a pure Dart billing engine for ERP, POS, checkout, and invoicing flows.
It calculates taxes, discounts, and final totals with a step-by-step audit trail so the result is both accurate and explainable.

Built for Flutter and Dart apps that need deterministic invoicing logic.

## Features

- Supports `TaxMode.none`, `TaxMode.exclusive`, and `TaxMode.inclusive`
- Handles item-level and bill-level discounts
- Supports percentage and fixed discounts
- Recalculates net, tax, and gross totals automatically
- Returns a detailed audit trail for every calculation
- Works in Flutter, backend, CLI, and web apps

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  erp_calculator: ^1.0.0
```

Then run:

```bash
dart pub get
```

## Quick start

```dart
import 'package:erp_calculator/erp_calculator.dart';

void main() {
  final result = BillingEngine.calculate(
    items: const [
      LineItem(
        id: 'sku-1',
        name: 'Laptop',
        unitPrice: 5000,
        qty: 1,
        taxMode: TaxMode.exclusive,
        taxRate: 14,
      ),
    ],
    billDiscounts: const [],
  );

  print(result.totalGross); // 5700.0
}
```

## Core concepts

Every line item has three money values:

| Term | Meaning |
| --- | --- |
| `net` | Price before tax |
| `tax` | Tax amount |
| `gross` | Final price the customer pays |

Rule:

```text
gross = net + tax
```

## Tax modes

### 1. Exclusive tax

Tax is added on top of the stated price.

```text
net   = price
tax   = net * rate
gross = net + tax
```

### 2. Inclusive tax

Tax is already included in the stated price.

```text
gross = price
net   = gross / (1 + rate)
tax   = gross - net
```

### 3. No tax

```text
net = gross = price
tax = 0
```

## Discounts

### Item-level discounts

Apply directly to one product or service line:

```dart
const item = LineItem(
  id: 'chair-1',
  name: 'Chair',
  unitPrice: 200,
  qty: 3,
  taxMode: TaxMode.exclusive,
  taxRate: 15,
  discountValue: 10,
  discountType: DiscountType.percentage,
  discountApplyOn: DiscountApplyOn.gross,
);
```

Supported options:

- Percentage or fixed amount
- Applied on `gross` or `net`

### Bill-level discounts

Applied after all line items are calculated:

```dart
const billDiscount = BillDiscount(
  id: 'promo-5',
  value: 5,
  type: DiscountType.percentage,
  applyOn: DiscountApplyOn.gross,
);
```

Bill discounts are distributed proportionally across lines and can be stacked sequentially.

## Full example

```dart
import 'package:erp_calculator/erp_calculator.dart';

void main() {
  final result = BillingEngine.calculate(
    items: const [
      LineItem(
        id: 'chair-1',
        name: 'Chair',
        unitPrice: 200,
        qty: 3,
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

  print(result.totalGross);
  print(result.totalSaved);
}
```

## Output

`BillResult` includes the final aggregated totals:

| Field | Description |
| --- | --- |
| `subtotalNet` | Net total after item discounts, before bill discounts |
| `subtotalTax` | Tax total after item discounts, before bill discounts |
| `subtotalGross` | Gross total after item discounts, before bill discounts |
| `billDiscountAmount` | Total saved from bill-level discounts |
| `totalNet` | Final net amount |
| `totalTax` | Final tax amount |
| `totalGross` | Final amount the customer pays |
| `totalSaved` | Total savings from item and bill discounts |
| `lineResults` | Per-item breakdown |
| `billSteps` | Audit trail for bill-level discounts |

Each `LineItemResult` includes:

| Field | Description |
| --- | --- |
| `basePrice` | `unitPrice * qty` |
| `net` | Final net amount for the line |
| `tax` | Tax amount for the line |
| `gross` | Final line total |
| `discountAmount` | Saved amount on the line |
| `steps` | Full audit trail |

## Audit trail

Each line result includes a `steps` list with:

- Calculation labels
- Exact formulas
- Final values

Example:

```text
100.00 * 15% = 15.00
```

This is useful for:

- Receipts
- Debugging
- Financial transparency

## When to use it

Use this package when you need deterministic pricing logic for:

- POS systems
- E-commerce checkouts
- ERP systems
- Invoice generators
- Accounting tools
- Quotation builders

Because the engine is stateless and side-effect free, it is safe to call from UI code, services, isolates, and tests.

## Example app

See [example/main.dart](example/main.dart) for a runnable Dart example and [example/lib/main.dart](example/lib/main.dart) for the Flutter demo app.
