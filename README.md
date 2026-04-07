🧮 ERP Calculator

A powerful, pure-Dart billing engine that calculates taxes, discounts, and full invoice totals with a complete step-by-step audit trail.

Built for Flutter & Dart apps that need accurate, transparent invoicing logic.

✨ Features
✅ Supports exclusive, inclusive, and no tax modes
✅ Handles item-level and bill-level discounts
✅ Supports percentage and fixed discounts
✅ Automatically recalculates net, tax, and gross
✅ Generates a full audit trail for every calculation
✅ Works in Flutter, backend, CLI, and web apps
📦 Installation

Add to your pubspec.yaml:

dependencies:
  erp_calculator: ^1.0.0

Then run:

flutter pub get
# or
dart pub get
🚀 Quick Example
import 'package:erp_calculator/erp_calculator.dart';

final item = LineItem(
  name: 'Laptop',
  unitPrice: 5000,
  qty: 1,
  taxMode: TaxMode.exclusive,
  taxRate: 14,
);

final result = BillingEngine.calculate(
  items: [item],
  billDiscounts: [],
);

print(result.totalGross); // 5700.00
🧠 Core Concepts

Every item has 3 values:

Term	Meaning
Net	Price before tax
Tax	Tax amount
Gross	Final price (Net + Tax)

Rule: Gross = Net + Tax

💰 Tax Modes
1. Exclusive Tax

Tax is added on top of the price.

Net   = Price
Tax   = Net × rate
Gross = Net + Tax
2. Inclusive Tax

Tax is already included in the price.

Gross = Price
Net   = Gross ÷ (1 + rate)
Tax   = Gross − Net
3. No Tax
Net = Gross = Price
Tax = 0
🎯 Discounts
🔹 Item-Level Discounts

Apply directly to a product.

discount: ItemDiscount(
  value: 10,
  type: DiscountType.percentage,
  applyOn: DiscountApplyOn.gross,
)

Options:

Percentage or Fixed
Apply on:
gross (after tax)
net (before tax)
🔹 Bill-Level Discounts

Applied after all items are calculated.

final billDiscount = BillDiscount(
  value: 5,
  type: DiscountType.percentage,
  applyOn: DiscountApplyOn.gross,
);

✔ Distributed proportionally across all items
✔ Supports multiple stacked discounts

🧾 Full Example
final items = [
  LineItem(
    name: 'Chair',
    unitPrice: 200,
    qty: 3,
    taxMode: TaxMode.exclusive,
    taxRate: 15,
    discount: ItemDiscount(
      value: 10,
      type: DiscountType.percentage,
      applyOn: DiscountApplyOn.gross,
    ),
  )
];

final result = BillingEngine.calculate(
  items: items,
  billDiscounts: [
    BillDiscount(
      value: 5,
      type: DiscountType.percentage,
      applyOn: DiscountApplyOn.gross,
    ),
  ],
);

print(result.totalGross);
print(result.totalSaved);
📊 Output
Bill Result
Field	Description
totalNet	Final net amount
totalTax	Final tax
totalGross	Amount customer pays
totalSaved	Total discount
subtotalGross	Before bill discounts
lineResults	Per-item breakdown
Item Result
Field	Description
basePrice	unit × qty
net	After discount
tax	Tax value
gross	Final item total
discountAmount	Saved amount
steps	Full audit trail
🔍 Audit Trail

Each item includes a steps list:

Calculation labels
Exact formulas
Final values

Example:

100 × 15% = 15

Perfect for:

Receipts
Debugging
Financial transparency
❓ FAQ
Can I use both item and bill discounts?

Yes. Item discounts apply first, then bill discounts.

What if discount > price?

It’s automatically capped — no negative values.

Can I stack bill discounts?

Yes. They are applied sequentially.

Does it require Flutter?

No. It’s pure Dart.

🏗 Use Cases
POS systems
E-commerce checkouts
ERP systems
Invoice generators
Accounting tools
