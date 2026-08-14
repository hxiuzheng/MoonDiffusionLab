///|
/// 简单的重采样置信区间，用于在没有外部统计依赖时表达指标不确定性。
pub(all) struct BootstrapInterval {
  estimate : Double
  lower : Double
  upper : Double
  resamples : Int
} derive(Debug, Eq)

///|
fn next_index(state : Int, length : Int) -> Int {
  if length <= 0 {
    0
  } else {
    let next = (state * 1103515245 + 12345) % 2147483647
    (if next < 0 { -next } else { next }) % length
  }
}

///|
fn sample_mean(values : Array[Double], state : Int) -> Double {
  if values.length() == 0 {
    return 0.0
  }
  let mut seed = state
  let mut total = 0.0
  for _ in 0..<values.length() {
    seed = next_index(seed, 2147483647)
    total += values[next_index(seed, values.length())]
  }
  total / values.length().to_double()
}

///|
/// 计算均值的 bootstrap 置信区间。排序后取经验分位数，不假设正态分布。
pub fn bootstrap_mean(
  values : Array[Double],
  resamples : Int,
  seed : Int,
) -> BootstrapInterval {
  let safe_resamples = if resamples < 1 { 1 } else { resamples }
  let estimate = if values.length() == 0 {
    0.0
  } else {
    let mut total = 0.0
    for value in values {
      total += value
    }
    total / values.length().to_double()
  }
  let samples = Array::make(safe_resamples, 0.0)
  for i in 0..<safe_resamples {
    samples[i] = sample_mean(values, seed + i * 104729)
  }
  samples.sort()
  let lower_index = (safe_resamples.to_double() * 0.025).to_int()
  let upper_index = (safe_resamples.to_double() * 0.975).to_int()
  let safe_upper = if upper_index >= safe_resamples {
    safe_resamples - 1
  } else {
    upper_index
  }
  {
    estimate,
    lower: samples[lower_index],
    upper: samples[safe_upper],
    resamples: safe_resamples,
  }
}

///|
/// 将置信区间转换成一行报告文本。
pub fn interval_markdown(name : String, interval : BootstrapInterval) -> String {
  "| " +
  name +
  " | " +
  interval.estimate.to_string() +
  " | " +
  interval.lower.to_string() +
  " | " +
  interval.upper.to_string() +
  " | " +
  interval.resamples.to_string() +
  " |\n"
}

///|
/// 对结果中的 Wasserstein 指标计算重采样区间。
pub fn wasserstein_interval(
  results : Array[@experiment.ExperimentResult],
  resamples : Int,
  seed : Int,
) -> BootstrapInterval {
  let values = Array::make(results.length(), 0.0)
  for i, result in results {
    values[i] = result.mean_wasserstein
  }
  bootstrap_mean(values, resamples, seed)
}
