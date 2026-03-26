/// Determines whether a discount [value] is interpreted as a percentage or a
/// fixed monetary amount.
enum DiscountType {
  /// [value] is a percentage (0–100). E.g. `10` → 10 % off.
  percentage,

  /// [value] is an absolute currency amount. E.g. `5.00` → 5.00 off.
  /// Clamped to the discount base so it can never exceed the item price.
  fixed,
}
