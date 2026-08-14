///|
/// 返回项目当前支持的全部程序生成基准数据集。
pub fn all_datasets() -> Array[BenchmarkDataset] {
  [Uniform1D, Gaussian1D, TwoMoons, SwissRoll, GmmRing, Bimodal]
}

///|
/// 返回项目当前支持的全部采样器。
pub fn all_samplers() -> Array[SamplerBackend] {
  [DDPM, DDIM, Euler]
}

///|
/// 一次数据集横向比较的结果摘要。
pub(all) struct DatasetBenchmarkSummary {
  dataset : BenchmarkDataset
  reports : Array[BenchmarkReport]
  best_sampler : SamplerBackend
  best_wasserstein : Double
  pass_rate : Double
} derive(Debug, Eq)

///|
/// 在同一数据集上运行三种采样器，返回可直接排序的摘要。
pub fn compare_samplers(
  dataset : BenchmarkDataset,
  seed : UInt64,
) -> DatasetBenchmarkSummary {
  let samplers = all_samplers()
  let first = run_benchmark(BenchmarkConfig::quick(dataset, samplers[0], seed))
  let reports = Array::make(samplers.length(), first)
  reports[0] = first
  let mut best_sampler = samplers[0]
  let mut best_wasserstein = first.metrics.wasserstein
  for i in 1..<samplers.length() {
    let report = run_benchmark(
      BenchmarkConfig::quick(dataset, samplers[i], seed + i.to_uint64() * 31UL),
    )
    reports[i] = report
    if report.metrics.wasserstein < best_wasserstein {
      best_wasserstein = report.metrics.wasserstein
      best_sampler = samplers[i]
    }
  }
  let mut passed = 0
  for report in reports {
    if report.passed {
      passed += 1
    }
  }
  {
    dataset,
    reports,
    best_sampler,
    best_wasserstein,
    pass_rate: passed.to_double() / reports.length().to_double(),
  }
}

///|
/// 运行所有数据集的横向比较。
pub fn compare_all(seed : UInt64) -> Array[DatasetBenchmarkSummary] {
  let datasets = all_datasets()
  let first = compare_samplers(datasets[0], seed)
  let summaries = Array::make(datasets.length(), first)
  summaries[0] = first
  for i in 1..<datasets.length() {
    summaries[i] = compare_samplers(datasets[i], seed + i.to_uint64() * 97UL)
  }
  summaries
}

///|
/// 汇总横向比较的结果为 Markdown 表格。
pub fn summaries_markdown(summaries : Array[DatasetBenchmarkSummary]) -> String {
  let mut out = "| Dataset | Best sampler | Best W1 | Pass rate |\n|---|---|---:|---:|\n"
  for summary in summaries {
    let sampler = match summary.best_sampler {
      DDPM => "ddpm"
      DDIM => "ddim"
      Euler => "euler"
    }
    out += "| " +
      dataset_name(summary.dataset) +
      " | " +
      sampler +
      " | " +
      summary.best_wasserstein.to_string() +
      " | " +
      summary.pass_rate.to_string() +
      " |\n"
  }
  out
}

///|
/// 汇总横向比较结果为 JSON 数组，保留每个数据集的最佳采样器。
pub fn summaries_json(summaries : Array[DatasetBenchmarkSummary]) -> String {
  let mut out = "["
  for i, summary in summaries {
    let sampler = match summary.best_sampler {
      DDPM => "ddpm"
      DDIM => "ddim"
      Euler => "euler"
    }
    out += "{\"dataset\":\"" +
      dataset_name(summary.dataset) +
      "\",\"best_sampler\":\"" +
      sampler +
      "\",\"best_wasserstein\":" +
      summary.best_wasserstein.to_string() +
      ",\"pass_rate\":" +
      summary.pass_rate.to_string() +
      "}"
    if i + 1 < summaries.length() {
      out += ","
    }
  }
  out + "]"
}

///|
/// 返回横向比较中通过率达到阈值的数据集数量。
pub fn healthy_dataset_count(
  summaries : Array[DatasetBenchmarkSummary],
  minimum_rate : Double,
) -> Int {
  let mut count = 0
  for summary in summaries {
    if summary.pass_rate >= minimum_rate {
      count += 1
    }
  }
  count
}

///|
/// 计算全套数据集的平均通过率，作为一次发布前的快速健康指标。
pub fn overall_pass_rate(summaries : Array[DatasetBenchmarkSummary]) -> Double {
  if summaries.length() == 0 {
    return 0.0
  }
  let mut total = 0.0
  for summary in summaries {
    total += summary.pass_rate
  }
  total / summaries.length().to_double()
}

///|
/// 判断整套横向比较是否达到发布前的最低健康门槛。
pub fn registry_is_healthy(
  summaries : Array[DatasetBenchmarkSummary],
  minimum_rate : Double,
) -> Bool {
  summaries.length() > 0 && overall_pass_rate(summaries) >= minimum_rate
}

///|
/// 返回横向比较中表现最好的报告；空集合返回 None。
pub fn best_report(summary : DatasetBenchmarkSummary) -> BenchmarkReport? {
  if summary.reports.length() == 0 {
    return None
  }
  let mut best = summary.reports[0]
  for report in summary.reports[1:] {
    if report.metrics.wasserstein < best.metrics.wasserstein {
      best = report
    }
  }
  Some(best)
}

///|
/// 判断一个数据集是否至少有一个采样器通过基准门槛。
pub fn dataset_has_passing_sampler(summary : DatasetBenchmarkSummary) -> Bool {
  for report in summary.reports {
    if report.passed {
      return true
    }
  }
  false
}

///|
/// 统计横向比较中通过的采样器数量。
pub fn passing_sampler_count(summary : DatasetBenchmarkSummary) -> Int {
  let mut count = 0
  for report in summary.reports {
    if report.passed {
      count += 1
    }
  }
  count
}

///|
/// 返回该数据集的采样器覆盖数量，便于报告完整性检查。
pub fn sampler_coverage(summary : DatasetBenchmarkSummary) -> Int {
  summary.reports.length()
}
