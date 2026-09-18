part of 'number.dart';

/// Integer square root by Newton's method. Dart's BigInt has no sqrt, and
/// exactness checks need one: `sqrt(9/4)` can only stay exact if we can
/// prove 9 and 4 are perfect squares.
BigInt _integerSqrt(BigInt n) {
  if (n.isNegative) {
    throw const MathError(MathErrorKind.domainError, 'Square root of a negative integer');
  }
  if (n < BigInt.two) return n;

  // Seed from the double approximation where it's safe, otherwise from a
  // bit-length estimate, which stays correct for values beyond 2^53.
  var x = n.bitLength > 1000
      ? BigInt.one << ((n.bitLength + 1) >> 1)
      : BigInt.from(math.sqrt(n.toDouble()).floor() + 1);

  while (true) {
    final next = (x + n ~/ x) >> 1;
    if (next >= x) break;
    x = next;
  }
  return x;
}

/// The exact integer nth root of [n], or null when [n] isn't a perfect
/// nth power — the test that decides whether a root stays exact.
BigInt? _exactIntegerRoot(BigInt n, int degree) {
  if (degree <= 0) return null;
  if (n == BigInt.zero) return BigInt.zero;
  if (n == BigInt.one) return BigInt.one;
  if (n.isNegative) {
    if (degree.isEven) return null;
    final positive = _exactIntegerRoot(-n, degree);
    return positive == null ? null : -positive;
  }
  if (degree == 1) return n;
  if (degree == 2) {
    final root = _integerSqrt(n);
    return root * root == n ? root : null;
  }

  // Newton's method on integers for the general case.
  final d = BigInt.from(degree);
  var x = BigInt.one << ((n.bitLength ~/ degree) + 1);
  while (true) {
    final next = ((d - BigInt.one) * x + n ~/ x.pow(degree - 1)) ~/ d;
    if (next >= x) break;
    x = next;
  }
  return x.pow(degree) == n ? x : null;
}
