import 'dart:math' as math;

double clamp(num min, num input, num max) {
  return math.max(min.toDouble(), math.min(input.toDouble(), max.toDouble()));
}

double truncate(double value, [int decimals = 0]) {
  return double.parse(value.toStringAsFixed(decimals));
}

double lerp(double x, double y, double t) {
  return (1 - t) * x + t * y;
}

double damp(double x, double y, double lambda, double deltaTime) {
  return lerp(x, y, 1 - math.exp(-lambda * deltaTime));
}

double modulo(double n, double d) {
  return ((n % d) + d) % d;
}
