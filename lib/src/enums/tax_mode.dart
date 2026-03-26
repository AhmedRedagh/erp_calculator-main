/// Describes how tax relates to a [LineItem]'s unit price.
enum TaxMode {
  /// Tax is added **on top** of the stated price.
  ///
  /// ```
  /// gross = net + (net × rate)
  /// ```
  exclusive,

  /// Tax is already **embedded** in the stated price.
  ///
  /// ```
  /// net = gross / (1 + rate)
  /// tax = gross − net
  /// ```
  inclusive,

  /// No tax is applied. `net == gross`.
  none,
}
