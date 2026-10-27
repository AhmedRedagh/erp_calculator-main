# Changelog

## 1.1.0

- Fixed `BillResult.totalSaved` under-reporting savings when a discount is
  applied on net. It is now `originalGross - totalGross`, so it includes the
  tax removed by net discounts.
- Added `BillResult.overallDiscountPercentage` (`totalSaved / originalGross`).
  `billDiscountDisplayPercentage` is unchanged and still covers bill-level
  discounts only.
- Added `BillResult.billDiscountPercentageOfSubtotalGross`: the bill discount
  as a share of the bill after item discounts (`billDiscountAmount /
  subtotalGross`). A fixed 150 off a 300 bill gives 50%.
- Added `BillResult.originalGross`, `BillResult.itemDiscountImpactOnGross`,
  `LineItemResult.originalGross` and `LineItemResult.discountImpactOnGross`.
- Net, tax and gross totals are unchanged.
- `BillResult` and `LineItemResult` constructors gain the new required fields.
  This only matters if you construct these results yourself (for example in
  test fakes).
- Demo: inputs no longer lose focus after each keystroke; the summary shows the
  real total saved, the overall discount %, and the bill discount % separately;
  bill-step labels are translated in Arabic.

## 1.0.0

- Initial public release.
- Added support for inclusive, exclusive, and no-tax calculations.
- Added item-level and bill-level discounts.
- Added step-by-step calculation audit output.
