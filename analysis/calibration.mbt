///|
/// Reusable quality-gate calibration for benchmark reports.
///
/// A fixed threshold is convenient for demos, but a project that runs the
/// same benchmark on several platforms needs a threshold derived from the
/// observed validation distribution. This module keeps that calculation
/// deterministic and makes the resulting policy auditable in CI logs.
pub(all) struct CalibrationResult {
  sample_count : Int
  target_pass_rate : Double
  percentile : Double
  percentile_value : Double
  mean : Double
  standard_deviation : Double
  recommended_threshold : Double
  observed_pass_rate : Double
} derive(Debug, Eq)

///|
fn clamp_probability(value : Double) -> Double {
  if value < 0.0 {
    0.0
  } else if value > 1.0 {
    1.0
  } else {
    value
  }
}

///|
fn sorted_wasserstein(
  reports : Array[@benchmark.BenchmarkReport],
) -> Array[Double] {
  let values = Array::new()
  for report in reports {
    values.push(report.metrics.wasserstein)
  }
  // Insertion sort is small, allocation-free beyond the result array, and
  // stable across MoonBit targets; benchmark suites are intentionally small.
  for i in 1..<values.length() {
    let value = values[i]
    let mut j = i
    while j > 0 && values[j - 1] > value {
      values[j] = values[j - 1]
      j -= 1
    }
    values[j] = value
  }
  values
}

///|
pub fn percentile(values : Array[Double], probability : Double) -> Double {
  if values.length() == 0 {
    return 0.0
  }
  let p = clamp_probability(probability)
  let position = p * (values.length() - 1).to_double()
  let lower = position.to_int()
  let upper = if lower + 1 >= values.length() { lower } else { lower + 1 }
  let fraction = position - lower.to_double()
  values[lower] + (values[upper] - values[lower]) * fraction
}

///|
pub fn mean(values : Array[Double]) -> Double {
  if values.length() == 0 {
    return 0.0
  }
  let mut total = 0.0
  for value in values {
    total += value
  }
  total / values.length().to_double()
}

///|
pub fn standard_deviation(values : Array[Double], average : Double) -> Double {
  if values.length() < 2 {
    return 0.0
  }
  let mut squared = 0.0
  for value in values {
    let delta = value - average
    squared += delta * delta
  }
  (squared / (values.length() - 1).to_double()).sqrt()
}

///|
/// Calibrate a threshold so at least `target_pass_rate` of validation reports
/// pass. The percentile is the complementary quantile, with a small standard
/// deviation guard to avoid overfitting a tiny validation sample.
pub fn calibrate(
  reports : Array[@benchmark.BenchmarkReport],
  target_pass_rate : Double,
) -> CalibrationResult {
  let values = sorted_wasserstein(reports)
  let target = clamp_probability(target_pass_rate)
  let p = 1.0 - target
  let average = mean(values)
  let deviation = standard_deviation(values, average)
  let quantile = percentile(values, p)
  let deviation_buffer = deviation * 0.1
  let threshold = if quantile > average + deviation_buffer {
    quantile
  } else {
    average + deviation_buffer
  }
  let mut passed = 0
  for value in values {
    if value <= threshold {
      passed += 1
    }
  }
  let observed = if values.length() == 0 {
    0.0
  } else {
    passed.to_double() / values.length().to_double()
  }
  {
    sample_count: values.length(),
    target_pass_rate: target,
    percentile: p,
    percentile_value: quantile,
    mean: average,
    standard_deviation: deviation,
    recommended_threshold: threshold,
    observed_pass_rate: observed,
  }
}

///|
pub fn accepts(result : CalibrationResult, wasserstein : Double) -> Bool {
  wasserstein >= 0.0 && wasserstein <= result.recommended_threshold
}

///|
pub fn calibration_markdown(result : CalibrationResult) -> String {
  "| Calibration field | Value |\n" +
  "|---|---:|\n" +
  "| Samples | " +
  result.sample_count.to_string() +
  " |\n" +
  "| Target pass rate | " +
  result.target_pass_rate.to_string() +
  " |\n" +
  "| Quantile | " +
  result.percentile.to_string() +
  " |\n" +
  "| Quantile value | " +
  result.percentile_value.to_string() +
  " |\n" +
  "| Mean Wasserstein | " +
  result.mean.to_string() +
  " |\n" +
  "| Standard deviation | " +
  result.standard_deviation.to_string() +
  " |\n" +
  "| Recommended threshold | " +
  result.recommended_threshold.to_string() +
  " |\n" +
  "| Observed pass rate | " +
  result.observed_pass_rate.to_string() +
  " |\n"
}
