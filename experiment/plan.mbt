///|
/// 一组可重复执行的实验案例。案例不直接持有样本，避免计划对象占用大量内存。
pub(all) struct ExperimentCase {
  name : String
  config : @benchmark.BenchmarkConfig
  repeats : Int
} derive(Debug, Eq)

///|
/// 统计同一案例多次运行后的稳定性和质量。
pub(all) struct ExperimentResult {
  name : String
  dataset : @benchmark.BenchmarkDataset
  sampler : @benchmark.SamplerBackend
  repeats : Int
  mean_wasserstein : Double
  std_wasserstein : Double
  min_wasserstein : Double
  max_wasserstein : Double
  mean_error : Double
  variance_error : Double
  mean_coverage : Double
  pass_rate : Double
  best_seed : UInt64
} derive(Debug, Eq)

///|
/// 创建一个案例并规范重复次数。
pub fn ExperimentCase::new(
  name : String,
  config : @benchmark.BenchmarkConfig,
  repeats : Int,
) -> ExperimentCase {
  { name, config, repeats: if repeats < 1 { 1 } else { repeats } }
}

///|
/// 为每次重复生成独立但可复现的配置。
fn config_for_repeat(
  config : @benchmark.BenchmarkConfig,
  index : Int,
) -> @benchmark.BenchmarkConfig {
  {
    dataset: config.dataset,
    sampler: config.sampler,
    target_count: config.target_count,
    sample_count: config.sample_count,
    diffusion_steps: config.diffusion_steps,
    sampling_steps: config.sampling_steps,
    seed: config.seed + index.to_uint64() * 7919UL,
  }
}

///|
fn average(values : Array[Double]) -> Double {
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
fn standard_deviation(values : Array[Double], mean : Double) -> Double {
  if values.length() <= 1 {
    return 0.0
  }
  let mut total = 0.0
  for value in values {
    let delta = value - mean
    total += delta * delta
  }
  (total / (values.length() - 1).to_double()).sqrt()
}

///|
/// 重复执行一个案例并聚合结果，适合比较不同采样器的随机稳定性。
pub fn run_case(case : ExperimentCase) -> ExperimentResult {
  let count = case.repeats
  let initial_report = @benchmark.run_benchmark(
    config_for_repeat(case.config, 0),
  )
  let wassersteins = Array::make(count, initial_report.metrics.wasserstein)
  let mean_errors = Array::make(count, initial_report.metrics.mean_error)
  let variance_errors = Array::make(
    count,
    initial_report.metrics.variance_error,
  )
  let coverages = Array::make(count, initial_report.metrics.coverage)
  let mut best_value = initial_report.metrics.wasserstein
  let mut best_seed = case.config.seed
  let mut passed = 0
  if initial_report.passed {
    passed += 1
  }
  for i in 1..<count {
    let report = @benchmark.run_benchmark(config_for_repeat(case.config, i))
    wassersteins[i] = report.metrics.wasserstein
    mean_errors[i] = report.metrics.mean_error
    variance_errors[i] = report.metrics.variance_error
    coverages[i] = report.metrics.coverage
    if report.metrics.wasserstein < best_value {
      best_value = report.metrics.wasserstein
      best_seed = case.config.seed + i.to_uint64() * 7919UL
    }
    if report.passed {
      passed += 1
    }
  }
  let mean_wasserstein = average(wassersteins)
  let mut min_wasserstein = wassersteins[0]
  let mut max_wasserstein = wassersteins[0]
  for value in wassersteins {
    if value < min_wasserstein {
      min_wasserstein = value
    }
    if value > max_wasserstein {
      max_wasserstein = value
    }
  }
  {
    name: case.name,
    dataset: case.config.dataset,
    sampler: case.config.sampler,
    repeats: count,
    mean_wasserstein,
    std_wasserstein: standard_deviation(wassersteins, mean_wasserstein),
    min_wasserstein,
    max_wasserstein,
    mean_error: average(mean_errors),
    variance_error: average(variance_errors),
    mean_coverage: average(coverages),
    pass_rate: passed.to_double() / count.to_double(),
    best_seed,
  }
}

///|
/// 执行案例列表，结果顺序与输入计划保持一致。
pub fn run_plan(cases : Array[ExperimentCase]) -> Array[ExperimentResult] {
  if cases.length() == 0 {
    return []
  }
  let first = run_case(cases[0])
  let results = Array::make(cases.length(), first)
  results[0] = first
  for i in 1..<cases.length() {
    results[i] = run_case(cases[i])
  }
  results
}

///|
/// 构造完整的六数据集 × 三采样器回归计划。
pub fn default_plan(seed : UInt64, repeats : Int) -> Array[ExperimentCase] {
  let datasets = [
    @benchmark.Uniform1D,
    @benchmark.Gaussian1D,
    @benchmark.TwoMoons,
    @benchmark.SwissRoll,
    @benchmark.GmmRing,
    @benchmark.Bimodal,
  ]
  let samplers = [@benchmark.DDPM, @benchmark.DDIM, @benchmark.Euler]
  let total = datasets.length() * samplers.length()
  let first_config = @benchmark.BenchmarkConfig::quick(
    datasets[0],
    samplers[0],
    seed,
  )
  let cases = Array::make(
    total,
    ExperimentCase::new("placeholder", first_config, repeats),
  )
  let mut position = 0
  for dataset in datasets {
    for sampler in samplers {
      let config = @benchmark.BenchmarkConfig::quick(
        dataset,
        sampler,
        seed + position.to_uint64() * 101,
      )
      cases[position] = ExperimentCase::new(
        dataset_label(dataset) + "/" + sampler_label(sampler),
        config,
        repeats,
      )
      position += 1
    }
  }
  cases
}

///|
fn dataset_label(dataset : @benchmark.BenchmarkDataset) -> String {
  match dataset {
    @benchmark.Uniform1D => "uniform_1d"
    @benchmark.Gaussian1D => "gaussian_1d"
    @benchmark.TwoMoons => "two_moons"
    @benchmark.SwissRoll => "swiss_roll"
    @benchmark.GmmRing => "gmm_ring"
    @benchmark.Bimodal => "bimodal"
  }
}

///|
fn sampler_label(sampler : @benchmark.SamplerBackend) -> String {
  match sampler {
    @benchmark.DDPM => "ddpm"
    @benchmark.DDIM => "ddim"
    @benchmark.Euler => "euler"
  }
}
