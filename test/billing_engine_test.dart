import 'package:erp_calculator/erp_calculator.dart';
import 'package:test/test.dart';

// Rounds to 2 dp to match engine output.
double r(double v) => double.parse(v.toStringAsFixed(2));

void main() {
  group('TaxMode.none', () {
    test('net == gross, tax == 0', () {
      final result = BillingEngine.calculate(
        items: [
          const LineItem(
            id: '1',
            name: 'A',
            unitPrice: 100,
            qty: 2,
            taxMode: TaxMode.none,
          ),
        ],
        billDiscounts: [],
      );

      expect(result.lineResults.first.net, r(200));
      expect(result.lineResults.first.tax, r(0));
      expect(result.lineResults.first.gross, r(200));
    });
  });

  group('TaxMode.exclusive', () {
    test('tax is added on top', () {
      final result = BillingEngine.calculate(
        items: [
          const LineItem(
            id: '1',
            name: 'A',
            unitPrice: 100,
            qty: 1,
            taxMode: TaxMode.exclusive,
            taxRate: 15,
          ),
        ],
        billDiscounts: [],
      );

      final line = result.lineResults.first;
      expect(line.net, r(100));
      expect(line.tax, r(15));
      expect(line.gross, r(115));
    });

    test('uses each item taxRate', () {
      final result = BillingEngine.calculate(
        items: [
          const LineItem(
            id: '1',
            name: 'A',
            unitPrice: 200,
            qty: 1,
            taxMode: TaxMode.exclusive,
            taxRate: 5,
          ),
        ],
        billDiscounts: [],
      );

      final line = result.lineResults.first;
      expect(line.net, r(200));
      expect(line.tax, r(10));
      expect(line.gross, r(210));
    });
  });

  group('TaxMode.inclusive', () {
    test('tax is extracted from the stated price', () {
      final result = BillingEngine.calculate(
        items: [
          const LineItem(
            id: '1',
            name: 'A',
            unitPrice: 115,
            qty: 1,
            taxMode: TaxMode.inclusive,
            taxRate: 15,
          ),
        ],
        billDiscounts: [],
      );

      final line = result.lineResults.first;
      expect(line.gross, r(115));
      expect(line.net, r(100));
      expect(line.tax, r(15));
    });
  });

  group('Item discount - percentage on gross', () {
    test('10 % off gross, exclusive tax', () {
      final result = BillingEngine.calculate(
        items: [
          const LineItem(
            id: '1',
            name: 'A',
            unitPrice: 100,
            qty: 2,
            taxMode: TaxMode.exclusive,
            taxRate: 15,
            discountValue: 10,
            discountType: DiscountType.percentage,
            discountApplyOn: DiscountApplyOn.gross,
          ),
        ],
        billDiscounts: [],
      );

      final line = result.lineResults.first;
      expect(line.discountAmount, r(23));
      expect(line.gross, r(207));
      expect(line.net, r(r(207) / 1.15));
    });
  });

  group('Item discount - percentage on net', () {
    test('10 % off net re-applies tax on reduced base', () {
      final result = BillingEngine.calculate(
        items: [
          const LineItem(
            id: '1',
            name: 'A',
            unitPrice: 100,
            qty: 2,
            taxMode: TaxMode.exclusive,
            taxRate: 15,
            discountValue: 10,
            discountType: DiscountType.percentage,
            discountApplyOn: DiscountApplyOn.net,
          ),
        ],
        billDiscounts: [],
      );

      final line = result.lineResults.first;
      expect(line.discountAmount, r(20));
      expect(line.net, r(180));
      expect(line.gross, r(207));
    });
  });

  group('Item discount - fixed on gross', () {
    test('fixed 30 off gross', () {
      final result = BillingEngine.calculate(
        items: [
          const LineItem(
            id: '1',
            name: 'A',
            unitPrice: 100,
            qty: 1,
            taxMode: TaxMode.exclusive,
            taxRate: 15,
            discountValue: 30,
            discountType: DiscountType.fixed,
            discountApplyOn: DiscountApplyOn.gross,
          ),
        ],
        billDiscounts: [],
      );

      final line = result.lineResults.first;
      expect(line.discountAmount, r(30));
      expect(line.gross, r(85));
    });
  });

  group('BillDiscount - percentage on gross', () {
    test('5 % off total gross', () {
      final result = BillingEngine.calculate(
        items: [
          const LineItem(
            id: '1',
            name: 'A',
            unitPrice: 100,
            qty: 1,
            taxMode: TaxMode.exclusive,
            taxRate: 15,
          ),
        ],
        billDiscounts: [
          const BillDiscount(
            id: 'BD1',
            value: 5,
            type: DiscountType.percentage,
            applyOn: DiscountApplyOn.gross,
          ),
        ],
      );

      expect(result.billDiscountAmount, r(5.75));
      expect(result.totalGross, r(109.25));
    });
  });

  group('BillDiscount - percentage on net', () {
    test('10 % off net recalculates gross correctly', () {
      final result = BillingEngine.calculate(
        items: [
          const LineItem(
            id: '1',
            name: 'A',
            unitPrice: 100,
            qty: 1,
            taxMode: TaxMode.exclusive,
            taxRate: 15,
          ),
        ],
        billDiscounts: [
          const BillDiscount(
            id: 'BD1',
            value: 10,
            type: DiscountType.percentage,
            applyOn: DiscountApplyOn.net,
          ),
        ],
      );

      expect(result.totalNet, r(90));
      expect(result.totalGross, r(103.50));
    });

    test('mixed item tax rates are recalculated per line', () {
      final result = BillingEngine.calculate(
        items: [
          const LineItem(
            id: '1',
            name: 'A',
            unitPrice: 100,
            qty: 1,
            taxMode: TaxMode.exclusive,
            taxRate: 10,
          ),
          const LineItem(
            id: '2',
            name: 'B',
            unitPrice: 200,
            qty: 1,
            taxMode: TaxMode.exclusive,
            taxRate: 20,
          ),
        ],
        billDiscounts: [
          const BillDiscount(
            id: 'BD1',
            value: 30,
            type: DiscountType.fixed,
            applyOn: DiscountApplyOn.net,
          ),
        ],
      );

      expect(result.subtotalNet, r(300));
      expect(result.subtotalGross, r(350));
      expect(result.totalNet, r(270));
      expect(result.totalGross, r(315));
      expect(result.totalTax, r(45));
    });
  });

  group('Multi-line bill', () {
    test('subtotals are the sum of line results', () {
      final result = BillingEngine.calculate(
        items: [
          const LineItem(
            id: '1',
            name: 'A',
            unitPrice: 100,
            qty: 1,
            taxMode: TaxMode.exclusive,
            taxRate: 10,
          ),
          const LineItem(
            id: '2',
            name: 'B',
            unitPrice: 200,
            qty: 1,
            taxMode: TaxMode.exclusive,
            taxRate: 10,
          ),
        ],
        billDiscounts: [],
      );

      expect(result.subtotalNet, r(300));
      expect(result.subtotalTax, r(30));
      expect(result.subtotalGross, r(330));
      expect(result.totalGross, r(330));
    });
  });

  group('UI discount percentage outputs', () {
    test('line item returns display discount percentage and net prices', () {
      final result = BillingEngine.calculate(
        items: [
          const LineItem(
            id: '1',
            name: 'A',
            unitPrice: 200,
            qty: 1,
            taxMode: TaxMode.exclusive,
            taxRate: 15,
            discountValue: 30,
            discountType: DiscountType.fixed,
            discountApplyOn: DiscountApplyOn.gross,
          ),
        ],
        billDiscounts: [],
      );

      final line = result.lineResults.first;
      expect(line.originalPriceWithoutTax, r(200));
      expect(line.discountedPriceWithoutTax, r(170));
      expect(line.displayDiscountPercentage, r(15));
    });

    test('bill result returns footer discount percentage only', () {
      final result = BillingEngine.calculate(
        items: [
          const LineItem(
            id: '1',
            name: 'A',
            unitPrice: 200,
            qty: 1,
            taxMode: TaxMode.exclusive,
            taxRate: 15,
            discountValue: 30,
            discountType: DiscountType.fixed,
            discountApplyOn: DiscountApplyOn.gross,
          ),
        ],
        billDiscounts: [
          const BillDiscount(
            id: 'BD1',
            value: 10,
            type: DiscountType.fixed,
            applyOn: DiscountApplyOn.gross,
          ),
        ],
      );

      expect(result.subtotalNet, r(170));
      expect(result.billDiscountDisplayPercentage, r((10 / 170) * 100));
    });
  });

  group('Validation', () {
    test('throws ArgumentError for empty items list', () {
      expect(
        () => BillingEngine.calculate(
          items: [],
          billDiscounts: [],
        ),
        throwsArgumentError,
      );
    });

    test(
      'throws AssertionError for negative item taxRate',
      () {
        expect(
          () => LineItem(id: '1', name: 'A', unitPrice: 50, taxRate: -1),
          throwsA(isA<AssertionError>()),
        );
      },
    );
  });

  group('Model equality', () {
    test('identical LineItems are equal', () {
      const a = LineItem(id: '1', name: 'A', unitPrice: 50, taxRate: 5);
      const b = LineItem(id: '1', name: 'A', unitPrice: 50, taxRate: 5);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith preserves equality on unchanged fields', () {
      const original = LineItem(id: '1', name: 'A', unitPrice: 50, taxRate: 5);
      final copy = original.copyWith(unitPrice: 50);
      expect(original, equals(copy));
    });

    test('clearDiscount removes discountValue', () {
      const original = LineItem(
        id: '1',
        name: 'A',
        unitPrice: 50,
        taxRate: 5,
        discountValue: 10,
      );
      final cleared = original.copyWith(clearDiscount: true);
      expect(cleared.discountValue, isNull);
    });
  });
}
