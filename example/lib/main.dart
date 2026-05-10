import 'package:erp_calculator/erp_calculator.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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

    return MaterialApp(
      title: 'ERP Calculator Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: SummaryScreen(result: result),
    );
  }
}

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key, required this.result});

  final BillResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('ERP Calculator Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sample invoice result',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text('Subtotal gross: ${result.subtotalGross.toStringAsFixed(2)}'),
            Text('Final gross: ${result.totalGross.toStringAsFixed(2)}'),
            Text('Total saved: ${result.totalSaved.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}
