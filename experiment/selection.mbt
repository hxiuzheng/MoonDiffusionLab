///|
/// 采样器聚合结果，用于在多个数据集上做整体比较。
pub(all) struct SamplerSummary {
  sampler : @benchmark.SamplerBackend
  cases : Int
  mean_wasserstein : Double
  mean_coverage : Double
  mean_pass_rate : Double
  stable_cases : Int
} derive(Debug, Eq)

///|
fn same_sampler(
  left : @benchmark.SamplerBackend,
  right : @benchmark.SamplerBackend,
) -> Bool {
  match (left, right) {
    (@benchmark.DDPM, @benchmark.DDPM) => true
    (@benchmark.DDIM, @benchmark.DDIM) => true
    (@benchmark.Euler, @benchmark.Euler) => true
    _ => false
  }
}

///|
/// 汇总同一采样器在多个数据集上的结果。
pub fn summarize_sampler(
  results : Array[ExperimentResult],
  sampler : @benchmark.SamplerBackend,
) -> SamplerSummary {
  let mut cases = 0
  let mut total_wasserstein = 0.0
  let mut total_coverage = 0.0
  let mut total_pass_rate = 0.0
  let mut stable_cases = 0
  for result in results {
    if same_sampler(result.sampler, sampler) {
      cases += 1
      total_wasserstein += result.mean_wasserstein
      total_coverage += result.mean_coverage
      total_pass_rate += result.pass_rate
      if result.std_wasserstein < 0.5 {
        stable_cases += 1
      }
    }
  }
  let denominator = if cases == 0 { 1.0 } else { cases.to_double() }
  {
    sampler,
    cases,
    mean_wasserstein: total_wasserstein / denominator,
    mean_coverage: total_coverage / denominator,
    mean_pass_rate: total_pass_rate / denominator,
    stable_cases,
  }
}

///|
/// 输出三种采样器的汇总表。
pub fn sampler_summary_markdown(results : Array[ExperimentResult]) -> String {
  let samplers = [@benchmark.DDPM, @benchmark.DDIM, @benchmark.Euler]
  let mut out = "| Sampler | Cases | Mean W1 | Mean coverage | Mean pass rate | Stable cases |\n"
  out += "|---|---:|---:|---:|---:|---:|\n"
  for sampler in samplers {
    let summary = summarize_sampler(results, sampler)
    out += "| " +
      sampler_label(sampler) +
      " | " +
      summary.cases.to_string() +
      " | " +
      summary.mean_wasserstein.to_string() +
      " | " +
      summary.mean_coverage.to_string() +
      " | " +
      summary.mean_pass_rate.to_string() +
      " | " +
      summary.stable_cases.to_string() +
      " |\n"
  }
  out
}

///|
/// 在结果中筛选通过率达到阈值的案例，保留原顺序便于审计。
pub fn filter_by_pass_rate(
  results : Array[ExperimentResult],
  threshold : Double,
) -> Array[ExperimentResult] {
  let selected : Array[ExperimentResult] = []
  for result in results {
    if result.pass_rate >= threshold {
      selected.push(result)
    }
  }
  selected
}

///|
/// 返回稳定性最好且平均距离较低的案例；用于自动选择默认配置。
pub fn select_stable_best(
  results : Array[ExperimentResult],
) -> ExperimentResult? {
  let filtered = filter_by_pass_rate(results, 0.5)
  if filtered.length() == 0 {
    return best_result(results)
  }
  let mut best = filtered[0]
  for result in filtered[1:] {
    let result_score = result.mean_wasserstein + result.std_wasserstein * 0.5
    let best_score = best.mean_wasserstein + best.std_wasserstein * 0.5
    if result_score < best_score {
      best = result
    }
  }
  Some(best)
}
