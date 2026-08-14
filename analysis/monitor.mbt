///|
/// 回归监控策略，给 CI 或批量实验一个明确的通过/告警/失败判定。
pub(all) struct MonitorPolicy {
  max_wasserstein : Double
  max_mean_error : Double
  max_variance_error : Double
  min_coverage : Double
  min_pass_rate : Double
} derive(Debug, Eq)

///|
/// 监控判定的严重程度。
pub(all) enum MonitorStatus {
  Pass
  Warning
  Fail
} derive(Debug, Eq)

///|
/// 一次监控判定，包含可读原因以便直接写入 CI 日志。
pub(all) struct MonitorDecision {
  status : MonitorStatus
  score : Double
  reason : String
} derive(Debug, Eq)

///|
/// 创建一个适合教学回归和小样本实验的默认策略。
pub fn MonitorPolicy::default() -> MonitorPolicy {
  {
    max_wasserstein: 2.5,
    max_mean_error: 1.0,
    max_variance_error: 3.0,
    min_coverage: 0.35,
    min_pass_rate: 0.5,
  }
}

///|
/// 检查单条基准报告是否通过策略。
pub fn check_report(
  policy : MonitorPolicy,
  report : @benchmark.BenchmarkReport,
) -> MonitorDecision {
  let metrics = report.metrics
  let mut violations = 0
  let mut warnings = 0
  let mut reason = ""
  if metrics.wasserstein > policy.max_wasserstein {
    violations += 1
    reason += "wasserstein;"
  } else if metrics.wasserstein > policy.max_wasserstein * 0.8 {
    warnings += 1
    reason += "wasserstein-near-limit;"
  }
  if metrics.mean_error > policy.max_mean_error {
    violations += 1
    reason += "mean-error;"
  }
  if metrics.variance_error > policy.max_variance_error {
    violations += 1
    reason += "variance-error;"
  }
  if metrics.coverage < policy.min_coverage {
    violations += 1
    reason += "coverage;"
  } else if metrics.coverage < policy.min_coverage + 0.1 {
    warnings += 1
    reason += "coverage-near-limit;"
  }
  let score = 1.0 / (1.0 + metrics.wasserstein) * 0.4 +
    1.0 / (1.0 + metrics.mean_error) * 0.2 +
    1.0 / (1.0 + metrics.variance_error) * 0.2 +
    metrics.coverage * 0.2
  if violations > 0 {
    { status: Fail, score, reason }
  } else if warnings > 0 || !report.passed {
    {
      status: Warning,
      score,
      reason: if reason == "" {
        "benchmark-threshold"
      } else {
        reason
      },
    }
  } else {
    { status: Pass, score, reason: "ok" }
  }
}

///|
/// 对一组报告执行监控，返回最严重状态。
pub fn check_reports(
  policy : MonitorPolicy,
  reports : Array[@benchmark.BenchmarkReport],
) -> MonitorDecision {
  if reports.length() == 0 {
    return { status: Fail, score: 0.0, reason: "no-reports" }
  }
  let first = check_report(policy, reports[0])
  let mut worst = first
  let mut total_score = first.score
  let mut failed = if first.status is Fail { 1 } else { 0 }
  let mut warning = if first.status is Warning { 1 } else { 0 }
  let mut reason = first.reason
  for report in reports[1:] {
    let decision = check_report(policy, report)
    total_score += decision.score
    if decision.status is Fail {
      failed += 1
      worst = decision
    } else if decision.status is Warning {
      warning += 1
      if failed == 0 {
        worst = decision
      }
    }
    if decision.reason != "ok" {
      reason += decision.reason
    }
  }
  let status = if failed > 0 {
    MonitorStatus::Fail
  } else if warning > 0 {
    MonitorStatus::Warning
  } else {
    MonitorStatus::Pass
  }
  let _ = worst
  { status, score: total_score / reports.length().to_double(), reason }
}

///|
/// 生成适合 CI artifact 的监控摘要。
pub fn decision_markdown(decision : MonitorDecision) -> String {
  let status = match decision.status {
    Pass => "PASS"
    Warning => "WARNING"
    Fail => "FAIL"
  }
  "| Status | Score | Reason |\n|---|---:|---|\n| " +
  status +
  " | " +
  decision.score.to_string() +
  " | " +
  decision.reason +
  " |\n"
}
