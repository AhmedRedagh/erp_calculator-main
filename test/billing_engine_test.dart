import 'package:erp_calculator/erp_calculator.dart';
import 'package:test/test.dart';

// Rounds to 2 dp to match engine output.
double r(double v) => double.parse(v.toStringAsFixed(2));

void main() {
  // ─── Tax modes ────────────────────────────────────────────────────────────

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
        globalTaxRate: 15,
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
          ),
        ],
        billDiscounts: [],
        globalTaxRate: 15,
      );

      final line = result.lineResults.first;
      expect(line.net, r(100));
      expect(line.tax, r(15));
      expect(line.gross, r(115));
    });

    test('uses taxRateOverride when provided', () {
      final result = BillingEngine.calculate(
        items: [
          const LineItem(
            id: '1',
            name: 'A',
            unitPrice: 200,
            qty: 1,
            taxMode: TaxMode.exclusive,
            taxRateOverride: 5,
          ),
        ],
        billDiscounts: [],
        globalTaxRate: 20,
      );

      final line = result.lineResults.first;
      expect(line.net, r(200));
      expect(line.tax, r(10));   // 5% of 200
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
          ),
        ],
        billDiscounts: [],
        globalTaxRate: 15,
      );

      final line = result.lineResults.first;
      expect(line.gross, r(115));
      expect(line.net, r(100));
      expect(line.tax, r(15));
    });
  });

  // ─── Item discounts ───────────────────────────────────────────────────────

  group('Item discount — percentage on gross', () {
    test('10 % off gross, exclusive tax', () {
      final result = BillingEngine.calculate(
        items: [
          const LineItem(
            id: '1',
            name: 'A',
            unitPrice: 100,
            qty: 2,
            taxMode: TaxMode.exclusive,
            discountValue: 10,
            discountType: DiscountType.percentage,
            discountApplyOn: DiscountApplyOn.gross,
          ),
        ],
        billDiscounts: [],
        globalTaxRate: 15,
      );

      // base = 200, gross = 230, discount = 23, newGross = 207
      final line = result.lineResults.first;
      expect(line.discountAmount, r(23));
      expect(line.gross, r(207));
      expect(line.net, r(r(207) / 1.15));
    });
  });

  group('Item discount — percentage on net', () {
    test('10 % off net re-applies tax on reduced base', () {
      final result = BillingEngine.calculate(
        items: [
          const LineItem(
            id: '1',
            name: 'A',
            unitPrice: 100,
            qty: 2,
            taxMode: TaxMode.exclusive,
            discountValue: 10,
            discountType: DiscountType.percentage,
            discountApplyOn: DiscountApplyOn.net,
          ),
        ],
        billDiscounts: [],
        globalTaxRate: 15,
      );

      // base = 200 net, discount = 20, newNet = 180, newGross = 207
      final line = result.lineResults.first;
      expect(line.discountAmount, r(20));
      expect(line.net, r(180));
      expect(line.gross, r(207));
    });
  });

  group('Item discount — fixed on gross', () {
    test('fixed 30 off gross', () {
      final result = BillingEngine.calculate(
        items: [
          const LineItem(
            id: '1',
            name: 'A',
            unitPrice: 100,
            qty: 1,
            taxMode: TaxMode.exclusive,
            discountValue: 30,
            discountType: DiscountType.fixed,
            discountApplyOn: DiscountApplyOn.gross,
          ),
        ],
        billDiscounts: [],
        globalTaxRate: 15,
      );

      // gross = 115, discount = 30, newGross = 85
      final line = result.lineResults.first;
      expect(line.discountAmount, r(30));
      expect(line.gross, r(85));
    });
  });

  // ─── Bill-level discounts ─────────────────────────────────────────────────

  group('BillDiscount — percentage on gross', () {
    test('5 % off total gross', () {
      final result = BillingEngine.calculate(
        items: [
          const LineItem(
            id: '1',
            name: 'A',
            unitPrice: 100,
            qty: 1,
            taxMode: TaxMode.exclusive,
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
        globalTaxRate: 15,
      );

      // subtotalGross = 115, 5% = 5.75, totalGross = 109.25
      expect(result.billDiscountAmount, r(5.75));
      expect(result.totalGross, r(109.25));
    });
  });

  group('BillDiscount — percentage on net (re-applies tax)', () {
    test('10 % off net recalculates gross correctly', () {
      final result = BillingEngine.calculate(
        items: [
          const LineItem(
            id: '1',
            name: 'A',
            unitPrice: 100,
            qty: 1,
            taxMode: TaxMode.exclusive,
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
        globalTaxRate: 15,
      );

      // subtotalNet = 100, discount = 10, newNet = 90, newGross = 103.50
      expect(result.totalNet, r(90));
      expect(result.totalGross, r(103.50));
    });
  });

  // ─── Aggregated totals ────────────────────────────────────────────────────

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
          ),
          const LineItem(
            id: '2',
            name: 'B',
            unitPrice: 200,
            qty: 1,
            taxMode: TaxMode.exclusive,
          ),
        ],
        billDiscounts: [],
        globalTaxRate: 10,
      );

      expect(result.subtotalNet, r(300));
      expect(result.subtotalTax, r(30));
      expect(result.subtotalGross, r(330));
      expect(result.totalGross, r(330));
    });
  });

  // ─── Input validation ─────────────────────────────────────────────────────

  group('Validation', () {
    test('throws ArgumentError for empty items list', () {
      expect(
        () => BillingEngine.calculate(
          items: [],
          billDiscounts: [],
          globalTaxRate: 15,
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for negative globalTaxRate', () {
      expect(
        () => BillingEngine.calculate(
          items: [
            const LineItem(id: '1', name: 'A', unitPrice: 50),
          ],
          billDiscounts: [],
          globalTaxRate: -1,
        ),
        throwsArgumentError,
      );
    });
  });

  // ─── Model equality ───────────────────────────────────────────────────────

  group('Model equality', () {
    test('identical LineItems are equal', () {
      const a = LineItem(id: '1', name: 'A', unitPrice: 50);
      const b = LineItem(id: '1', name: 'A', unitPrice: 50);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith preserves equality on unchanged fields', () {
      const original = LineItem(id: '1', name: 'A', unitPrice: 50);
      final copy = original.copyWith(unitPrice: 50);
      expect(original, equals(copy));
    });

    test('clearDiscount removes discountValue', () {
      const original = LineItem(
        id: '1',
        name: 'A',
        unitPrice: 50,
        discountValue: 10,
      );
      final cleared = original.copyWith(clearDiscount: true);
      expect(cleared.discountValue, isNull);
    });
  });
}
