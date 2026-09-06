import 'dart:math' as math;

class RfInverseSolveResult {
  final List<double> values;
  final double residualNorm;
  final double regularization;
  final bool valid;
  final String reason;

  const RfInverseSolveResult({
    required this.values,
    required this.residualNorm,
    required this.regularization,
    required this.valid,
    required this.reason,
  });

  static const unavailable = RfInverseSolveResult(
    values: <double>[],
    residualNorm: double.infinity,
    regularization: 0,
    valid: false,
    reason: 'INSUFFICIENT_FORWARD_MODEL_OR_MEASUREMENTS',
  );
}

/// Solves a linearized inverse problem using Tikhonov/ridge regularization.
/// A is supplied by a validated forward propagation model; this class never
/// invents a tissue response matrix.
class RegularizedRfInverseSolver {
  final double lambda;
  const RegularizedRfInverseSolver({this.lambda = 0.01}) : assert(lambda > 0);

  RfInverseSolveResult solve({
    required List<List<double>> forwardMatrix,
    required List<double> observations,
    List<double>? weights,
  }) {
    if (forwardMatrix.isEmpty || observations.isEmpty ||
        forwardMatrix.length != observations.length ||
        forwardMatrix.any((r) => r.isEmpty || r.any((v) => !v.isFinite)) ||
        observations.any((v) => !v.isFinite)) return RfInverseSolveResult.unavailable;
    final columns = forwardMatrix.first.length;
    if (forwardMatrix.any((r) => r.length != columns) || columns == 0) {
      return RfInverseSolveResult.unavailable;
    }
    final w = weights ?? List<double>.filled(observations.length, 1.0);
    if (w.length != observations.length || w.any((v) => !v.isFinite || v <= 0)) {
      return RfInverseSolveResult.unavailable;
    }

    final ata = List.generate(columns, (_) => List<double>.filled(columns, 0));
    final aty = List<double>.filled(columns, 0);
    for (var i = 0; i < forwardMatrix.length; i++) {
      final row = forwardMatrix[i];
      final wi = w[i];
      for (var c = 0; c < columns; c++) {
        aty[c] += row[c] * wi * observations[i];
        for (var d = 0; d < columns; d++) ata[c][d] += row[c] * wi * row[d];
      }
    }
    for (var i = 0; i < columns; i++) ata[i][i] += lambda;
    final solution = _solve(ata, aty);
    if (solution == null || solution.any((v) => !v.isFinite)) {
      return RfInverseSolveResult.unavailable;
    }
    var residual = 0.0;
    for (var i = 0; i < forwardMatrix.length; i++) {
      var predicted = 0.0;
      for (var c = 0; c < columns; c++) predicted += forwardMatrix[i][c] * solution[c];
      final e = observations[i] - predicted;
      residual += w[i] * e * e;
    }
    return RfInverseSolveResult(
      values: solution,
      residualNorm: math.sqrt(residual),
      regularization: lambda,
      valid: true,
      reason: 'REGULARIZED_RF_FIELD_SOLUTION',
    );
  }

  List<double>? _solve(List<List<double>> a, List<double> b) {
    final n = b.length;
    final m = List.generate(n, (i) => [...a[i], b[i]]);
    for (var col = 0; col < n; col++) {
      var pivot = col;
      for (var row = col + 1; row < n; row++) {
        if (m[row][col].abs() > m[pivot][col].abs()) pivot = row;
      }
      if (m[pivot][col].abs() < 1e-12) return null;
      final tmp = m[col]; m[col] = m[pivot]; m[pivot] = tmp;
      final divisor = m[col][col];
      for (var j = col; j <= n; j++) m[col][j] /= divisor;
      for (var row = 0; row < n; row++) {
        if (row == col) continue;
        final factor = m[row][col];
        for (var j = col; j <= n; j++) m[row][j] -= factor * m[col][j];
      }
    }
    return List<double>.generate(n, (i) => m[i][n]);
  }
}
