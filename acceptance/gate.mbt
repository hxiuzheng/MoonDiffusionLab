///|
/// 一个可审计的单项发布门禁结果。
///
/// 门禁不依赖网络，也不依赖隐藏环境变量；每项都保留人类可读的
/// detail，方便把 CI 输出直接作为验收证据或问题定位入口。
pub(all) struct GateCheck {
  name : String
  passed : Bool
  detail : String
} derive(Debug, Eq)

///|
pub fn GateCheck::new(
  name : String,
  passed : Bool,
  detail : String,
) -> GateCheck {
  { name, passed, detail }
}

///|
/// 一次完整的发布前验收报告。
pub(all) struct AcceptanceReport {
  seed : UInt64
  checks : Array[GateCheck]
  benchmark_case_count : Int
  experiment_case_count : Int
  benchmark_pass_rate : Double
  experiment_pass_rate : Double
  quality_score : Double
  html_bytes : Int
  svg_bytes : Int
  ready : Bool
} derive(Debug, Eq)

///|
/// 判断导出的静态产物是否具备最小可用结构，而不是只检查文件非空。
pub fn artifact_is_valid(kind : String, payload : String) -> Bool {
  if payload.length() < 128 {
    false
  } else if kind == "html" {
    payload.contains("<!DOCTYPE html>") &&
    payload.contains("<svg") &&
    payload.contains("Step t =") &&
    payload.contains("MoonDiffusionLab")
  } else if kind == "svg" {
    payload.contains("<svg") &&
    payload.contains("</svg>") &&
    payload.contains("<circle") &&
    payload.contains("viewBox=")
  } else {
    false
  }
}

///|
/// 检查基准矩阵是否覆盖全部数据集，并且每个数据集都有全部采样后端。
pub fn matrix_is_complete(
  summaries : Array[@benchmark.DatasetBenchmarkSummary],
  expected_datasets : Int,
  expected_samplers : Int,
) -> Bool {
  if summaries.length() != expected_datasets {
    return false
  }
  for summary in summaries {
    if @benchmark.sampler_coverage(summary) != expected_samplers {
      return false
    }
  }
  true
}

///|
/// 统计门禁中失败的检查项，供 CLI 和机器读取报告复用。
pub fn failed_check_names(checks : Array[GateCheck]) -> String {
  let mut names = ""
  for check in checks {
    if !check.passed {
      if names != "" {
        names += ","
      }
      names += check.name
    }
  }
  if names == "" {
    "none"
  } else {
    names
  }
}

///|
/// 门禁结果是否全部通过。
pub fn checks_are_ready(checks : Array[GateCheck]) -> Bool {
  if checks.length() == 0 {
    return false
  }
  for check in checks {
    if !check.passed {
      return false
    }
  }
  true
}

///|
/// 把完整门禁输出成 Markdown，既适合人读，也适合在 CI artifact 中归档。
pub fn report_markdown(report : AcceptanceReport) -> String {
  let status = if report.ready { "PASS" } else { "FAIL" }
  let mut out = "# MoonDiffusionLab release acceptance gate\n\n"
  out += "- Status: " + status + "\n"
  out += "- Seed: " + report.seed.to_string() + "\n"
  out += "- Benchmark cases: " + report.benchmark_case_count.to_string() + "\n"
  out += "- Experiment cases: " +
    report.experiment_case_count.to_string() +
    "\n"
  out += "- Benchmark pass rate: " +
    report.benchmark_pass_rate.to_string() +
    "\n"
  out += "- Experiment pass rate: " +
    report.experiment_pass_rate.to_string() +
    "\n"
  out += "- Quality score: " + report.quality_score.to_string() + "\n"
  out += "- HTML bytes: " + report.html_bytes.to_string() + "\n"
  out += "- SVG bytes: " + report.svg_bytes.to_string() + "\n\n"
  out += "| Check | Result | Detail |\n|---|---|---|\n"
  for check in report.checks {
    let result = if check.passed { "PASS" } else { "FAIL" }
    out += "| " + check.name + " | " + result + " | " + check.detail + " |\n"
  }
  out += "\nFailed checks: " + failed_check_names(report.checks) + "\n"
  out
}

///|
/// 输出稳定字段，供脚本在不解析 Markdown 的情况下读取门禁状态。
pub fn report_json(report : AcceptanceReport) -> String {
  let mut checks_json = "["
  for i, check in report.checks {
    checks_json += "{\"name\":\"" +
      check.name +
      "\",\"passed\":" +
      check.passed.to_string() +
      ",\"detail\":\"" +
      check.detail +
      "\"}"
    if i + 1 < report.checks.length() {
      checks_json += ","
    }
  }
  checks_json += "]"
  "{" +
  "\"ready\":" +
  report.ready.to_string() +
  ",\"seed\":" +
  report.seed.to_string() +
  ",\"benchmark_case_count\":" +
  report.benchmark_case_count.to_string() +
  ",\"experiment_case_count\":" +
  report.experiment_case_count.to_string() +
  ",\"benchmark_pass_rate\":" +
  report.benchmark_pass_rate.to_string() +
  ",\"experiment_pass_rate\":" +
  report.experiment_pass_rate.to_string() +
  ",\"quality_score\":" +
  report.quality_score.to_string() +
  ",\"html_bytes\":" +
  report.html_bytes.to_string() +
  ",\"svg_bytes\":" +
  report.svg_bytes.to_string() +
  ",\"failed_checks\":\"" +
  failed_check_names(report.checks) +
  "\",\"checks\":" +
  checks_json +
  "}"
}

///|
fn count_reports(summaries : Array[@benchmark.DatasetBenchmarkSummary]) -> Int {
  let mut count = 0
  for summary in summaries {
    count += summary.reports.length()
  }
  count
}

///|
fn all_reports_have_samples(
  summaries : Array[@benchmark.DatasetBenchmarkSummary],
) -> Bool {
  for summary in summaries {
    for report in summary.reports {
      if report.sample_count <= 0 || report.target_count <= 0 {
        return false
      }
    }
  }
  true
}

///|
fn all_experiments_have_repeats(
  results : Array[@experiment.ExperimentResult],
) -> Bool {
  for result in results {
    if result.repeats < 1 || result.mean_coverage < 0.0 {
      return false
    }
  }
  true
}

///|
/// 执行真实的发布前工作链：
///
/// 1. 六个程序生成基准数据集 × 三个采样器；
/// 2. 18 个可复现实验案例的聚合；
/// 3. Two Moons 的多指标质量判定；
/// 4. 由同一采样轨迹生成 HTML 和 SVG 产物；
/// 5. 检查导出格式、样本完整性和固定 seed 的可复现性。
///
/// 该函数不上传数据、不调用网络，适合本地和三平台 CI 直接执行。
pub fn run_release_gate(seed : UInt64) -> AcceptanceReport {
  let summaries = @benchmark.compare_all(seed)
  let experiments = @experiment.run_plan(
    @experiment.default_plan(seed + 1000UL, 1),
  )
  let rng = @core.Rng::new(seed=seed + 2000UL)
  let target = @dataset.sample_two_moons(96, noise=0.05, rng)
  let sched = @schedule.DiffusionSchedule::create(24, @schedule.Cosine(s=0.008))
  let model = @model.AnalyticalModel::new(target, bandwidth=0.1)
  let (generated, trajectory) = @diffusion.sample_ddpm_analytical(
    96,
    model,
    sched,
    rng,
    record_interval=6,
  )
  let comparison = @analysis.compare(target, generated, 12, 0.5)
  let decision = @analysis.check_comparison(
    @analysis.ComparisonPolicy::default(),
    comparison,
  )
  let html = @visualize.generate_html_report(
    trajectory,
    title="MoonDiffusionLab release gate artifact",
  )
  let svg = @visualize.render_svg_scatter(
    generated,
    width=420,
    height=320,
    point_color="#00ffcc",
    bg_color="#121218",
  )
  let benchmark_rate = @benchmark.overall_pass_rate(summaries)
  let experiment_rate = @experiment.average_pass_rate(experiments)
  let benchmark_cases = count_reports(summaries)
  let matrix_ok = matrix_is_complete(summaries, 6, 3)
  let registry_ok = @benchmark.registry_is_healthy(summaries, 0.5)
  let sample_ok = all_reports_have_samples(summaries)
  let experiment_ok = experiments.length() == 18 &&
    all_experiments_have_repeats(experiments) &&
    experiment_rate >= 0.5
  let quality_ok = decision.passed && decision.score >= 0.35
  let html_ok = artifact_is_valid("html", html)
  let svg_ok = artifact_is_valid("svg", svg)
  let markdown_ok = @benchmark.summaries_markdown(summaries).contains(
      "| Dataset |",
    ) &&
    @experiment.results_markdown(experiments).contains("| Rank |") &&
    @analysis.comparison_decision_markdown(decision).contains("| Status |")
  let machine_export_ok = @benchmark.summaries_json(summaries).contains(
      "best_sampler",
    ) &&
    @experiment.results_csv(experiments).contains("best_seed")
  let reproducible_first = @benchmark.run_benchmark(
    @benchmark.BenchmarkConfig::quick(
      @benchmark.TwoMoons,
      @benchmark.DDIM,
      seed + 3000UL,
    ),
  )
  let reproducible_second = @benchmark.run_benchmark(
    @benchmark.BenchmarkConfig::quick(
      @benchmark.TwoMoons,
      @benchmark.DDIM,
      seed + 3000UL,
    ),
  )
  let reproducible_ok = @benchmark.report_json(reproducible_first) ==
    @benchmark.report_json(reproducible_second)
  let checks = [
    GateCheck::new(
      "benchmark-matrix",
      matrix_ok,
      "datasets=" +
      summaries.length().to_string() +
      ", samplers=3, cases=" +
      benchmark_cases.to_string(),
    ),
    GateCheck::new(
      "benchmark-health",
      registry_ok,
      "overall_pass_rate=" + benchmark_rate.to_string(),
    ),
    GateCheck::new(
      "sample-integrity", sample_ok, "all benchmark reports contain target and generated samples",
    ),
    GateCheck::new(
      "experiment-plan",
      experiment_ok,
      "cases=" +
      experiments.length().to_string() +
      ", pass_rate=" +
      experiment_rate.to_string(),
    ),
    GateCheck::new(
      "quality-thresholds",
      quality_ok,
      "score=" +
      decision.score.to_string() +
      ", failed=" +
      decision.failed_checks.to_string(),
    ),
    GateCheck::new(
      "html-artifact",
      html_ok,
      "bytes=" +
      html.length().to_string() +
      ", frames=" +
      trajectory.num_frames().to_string(),
    ),
    GateCheck::new(
      "svg-artifact",
      svg_ok,
      "bytes=" +
      svg.length().to_string() +
      ", points=" +
      generated.length().to_string(),
    ),
    GateCheck::new(
      "report-exporters",
      markdown_ok && machine_export_ok,
      "markdown, JSON and CSV exporters contain required headers",
    ),
    GateCheck::new(
      "seed-reproducibility", reproducible_ok, "same seed produces byte-identical benchmark JSON",
    ),
  ]
  {
    seed,
    checks,
    benchmark_case_count: benchmark_cases,
    experiment_case_count: experiments.length(),
    benchmark_pass_rate: benchmark_rate,
    experiment_pass_rate: experiment_rate,
    quality_score: decision.score,
    html_bytes: html.length(),
    svg_bytes: svg.length(),
    ready: checks_are_ready(checks),
  }
}
