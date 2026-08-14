///|
/// 对分布比较结果进行统一阈值判定，避免不同报告使用不同口径。
pub(all) struct ComparisonPolicy {
  max_energy_distance : Double
  max_mmd : Double
  min_intersection : Double
  min_quality_score : Double
  max_diversity_gap : Double
} derive(Debug, Eq)

///|
pub(all) struct ComparisonDecision {
  passed : Bool
  failed_checks : Int
  score : Double
  reason : String
} derive(Debug, Eq)

///|
/// 创建默认的分布比较策略。
pub fn ComparisonPolicy::default() -> ComparisonPolicy {
  {
    max_energy_distance: 2.0,
    max_mmd: 0.4,
    min_intersection: 0.25,
    min_quality_score: 0.35,
    max_diversity_gap: 0.25,
  }
}

///|
fn bounded_score(
  value : Double,
  limit : Double,
  higher_is_better : Bool,
) -> Double {
  if higher_is_better {
    if limit <= 0.0 {
      0.0
    } else {
      let score = value / limit
      if score > 1.0 {
        1.0
      } else if score < 0.0 {
        0.0
      } else {
        score
      }
    }
  } else if value <= 0.0 {
    1.0
  } else {
    let score = 1.0 - value / limit
    if score < 0.0 {
      0.0
    } else {
      score
    }
  }
}

///|
/// 根据策略检查多指标比较结果。
pub fn check_comparison(
  policy : ComparisonPolicy,
  comparison : DistributionComparison,
) -> ComparisonDecision {
  let mut failed = 0
  let mut reason = ""
  if comparison.energy_distance > policy.max_energy_distance {
    failed += 1
    reason += "energy;"
  }
  if comparison.mmd_rbf > policy.max_mmd {
    failed += 1
    reason += "mmd;"
  }
  if comparison.histogram_intersection < policy.min_intersection {
    failed += 1
    reason += "intersection;"
  }
  if comparison.quality_score < policy.min_quality_score {
    failed += 1
    reason += "quality;"
  }
  if comparison.diversity_gap > policy.max_diversity_gap {
    failed += 1
    reason += "diversity;"
  }
  let score = (
      bounded_score(
        comparison.energy_distance,
        policy.max_energy_distance,
        false,
      ) +
      bounded_score(comparison.mmd_rbf, policy.max_mmd, false) +
      bounded_score(
        comparison.histogram_intersection,
        policy.min_intersection,
        true,
      ) +
      bounded_score(comparison.quality_score, policy.min_quality_score, true) +
      bounded_score(comparison.diversity_gap, policy.max_diversity_gap, false)
    ) /
    5.0
  {
    passed: failed == 0,
    failed_checks: failed,
    score,
    reason: if reason == "" {
      "ok"
    } else {
      reason
    },
  }
}

///|
/// 以结构化 Markdown 输出比较判定，保留失败项便于人工复核。
pub fn comparison_decision_markdown(decision : ComparisonDecision) -> String {
  let status = if decision.passed { "PASS" } else { "FAIL" }
  "| Status | Score | Failed checks | Reason |\n|---|---:|---:|---|\n| " +
  status +
  " | " +
  decision.score.to_string() +
  " | " +
  decision.failed_checks.to_string() +
  " | " +
  decision.reason +
  " |\n"
}

///|
/// 对多组比较结果统计通过率。
pub fn comparison_pass_rate(
  policy : ComparisonPolicy,
  comparisons : Array[DistributionComparison],
) -> Double {
  if comparisons.length() == 0 {
    return 0.0
  }
  let mut passed = 0
  for comparison in comparisons {
    if check_comparison(policy, comparison).passed {
      passed += 1
    }
  }
  passed.to_double() / comparisons.length().to_double()
}
