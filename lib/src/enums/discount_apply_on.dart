/// The price base against which a discount is calculated.
enum DiscountApplyOn {
  /// Discount is calculated on the **tax-included** (gross) price.
  ///
  /// After the discount, net is back-calculated:
  /// ```
  /// newGross = gross − discountAmount
  /// newNet   = newGross / (1 + rate)
  /// ```
  gross,

  /// Discount is calculated on the **pre-tax** (net) price.
  ///
  /// Tax is **re-applied** on the reduced net, which yields a greater
  /// effective saving because it also lowers the taxable base:
  /// ```
  /// newNet   = net − discountAmount
  /// newGross = newNet × (1 + rate)
  /// ```
  net,
}
