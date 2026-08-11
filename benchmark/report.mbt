///|
fn dataset_name(dataset : BenchmarkDataset) -> String {
  match dataset {
    Uniform1D => "uniform_1d"
    Gaussian1D => "gaussian_1d"
    TwoMoons => "two_moons"
    SwissRoll => "swiss_roll"
    GmmRing => "gmm_ring"
    Bimodal => "bimodal"
  }
}

///|
fn sampler_name(sampler : SamplerBackend) -> String {
  match sampler {
    DDPM => "ddpm"
    DDIM => "ddim"
    Euler => "euler"
  }
}

///|
/// 将单条报告转换成无依赖 JSON，便于接入网页、Notebook 或 CI 工具。
pub fn report_json(report : BenchmarkReport) -> String {
  let m = report.metrics
  "{" +
  "\"dataset\":\"" +
  dataset_name(report.dataset) +
  "\", " +
  "\"sampler\":\"" +
  sampler_name(report.sampler) +
  "\", " +
  "\"seed\":" +
  report.seed.to_string() +
  ", " +
  "\"target_count\":" +
  report.target_count.to_string() +
  ", " +
  "\"sample_count\":" +
  report.sample_count.to_string() +
  ", " +
  "\"wasserstein\":" +
  m.wasserstein.to_string() +
  ", " +
  "\"mean_error\":" +
  m.mean_error.to_string() +
  ", " +
  "\"variance_error\":" +
  m.variance_error.to_string() +
  ", " +
  "\"coverage\":" +
  m.coverage.to_string() +
  ", " +
  "\"out_of_bounds\":" +
  m.out_of_bounds.to_string() +
  ", " +
  "\"passed\":" +
  report.passed.to_string() +
  "}"
}

///|
/// 输出可直接导入电子表格的 CSV 行。
pub fn report_csv_row(report : BenchmarkReport) -> String {
  let m = report.metrics
  dataset_name(report.dataset) +
  "," +
  sampler_name(report.sampler) +
  "," +
  report.seed.to_string() +
  "," +
  report.target_count.to_string() +
  "," +
  report.sample_count.to_string() +
  "," +
  m.wasserstein.to_string() +
  "," +
  m.mean_error.to_string() +
  "," +
  m.variance_error.to_string() +
  "," +
  m.coverage.to_string() +
  "," +
  m.out_of_bounds.to_string() +
  "," +
  report.passed.to_string()
}

///|
/// 输出带表头的批量 CSV 报告。
pub fn suite_csv(reports : Array[BenchmarkReport]) -> String {
  let mut out = "dataset,sampler,seed,target_count,sample_count,wasserstein,mean_error,variance_error,coverage,out_of_bounds,passed\n"
  for report in reports {
    out += report_csv_row(report) + "\n"
  }
  out
}

///|
/// 输出适合 README、Issue 或 CI artifact 的 Markdown 表格。
pub fn suite_markdown(reports : Array[BenchmarkReport]) -> String {
  let mut out = "| Dataset | Sampler | Wasserstein | Mean error | Variance error | Coverage | Result |\n"
  out += "|---|---|---:|---:|---:|---:|---|\n"
  for report in reports {
    let m = report.metrics
    let result = if report.passed { "PASS" } else { "REVIEW" }
    out += "| " +
      dataset_name(report.dataset) +
      " | " +
      sampler_name(report.sampler) +
      " | " +
      m.wasserstein.to_string() +
      " | " +
      m.mean_error.to_string() +
      " | " +
      m.variance_error.to_string() +
      " | " +
      m.coverage.to_string() +
      " | " +
      result +
      " |\n"
  }
  out
}

///|
/// 统计批量报告中的通过率。
pub fn suite_pass_rate(reports : Array[BenchmarkReport]) -> Double {
  if reports.length() == 0 {
    return 0.0
  }
  let mut passed = 0
  for report in reports {
    if report.passed {
      passed += 1
    }
  }
  passed.to_double() / reports.length().to_double()
}

///|
/// 批量报告是否满足最基本的回归门槛。
pub fn suite_is_healthy(
  reports : Array[BenchmarkReport],
  minimum_rate? : Double = 0.5,
) -> Bool {
  reports.length() > 0 && suite_pass_rate(reports) >= minimum_rate
}
