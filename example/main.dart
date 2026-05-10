import 'dart:io';

import 'package:erp_calculator/erp_calculator.dart';

void main() {
  final result = BillingEngine.calculate(
    items: const [
      LineItem(
        id: 'item-1',
        name: 'Keyboard',
        unitPrice: 120,
        qty: 2,
        taxMode: TaxMode.exclusive,
        taxRate: 15,
        discountValue: 10,
        discountType: DiscountType.percentage,
        discountApplyOn: DiscountApplyOn.net,
      ),
      LineItem(
        id: 'item-2',
        name: 'Mouse',
        unitPrice: 57.5,
        qty: 1,
        taxMode: TaxMode.inclusive,
        taxRate: 15,
      ),
    ],
    billDiscounts: const [
      BillDiscount(
        id: 'invoice-discount',
        value: 5,
        type: DiscountType.percentage,
        applyOn: DiscountApplyOn.gross,
      ),
    ],
  );

  stdout.writeln('Subtotal gross: ${result.subtotalGross.toStringAsFixed(2)}');
  stdout.writeln('Final gross: ${result.totalGross.toStringAsFixed(2)}');
  stdout.writeln('Total saved: ${result.totalSaved.toStringAsFixed(2)}');
}
