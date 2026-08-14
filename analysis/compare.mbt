///|
/// 两组分布的多指标比较结果。
pub(all) struct DistributionComparison {
  energy_distance : Double
  mmd_rbf : Double
  histogram_intersection : Double
  quality_score : Double
  target_nn_distance : Double
  generated_nn_distance : Double
  diversity_gap : Double
} derive(Debug, Eq)

///|
fn squared_distance(a : @core.Vec2, b : @core.Vec2) -> Double {
  let delta = a - b
  delta.norm_sqr()
}

///|
fn average_pair_distance(
  first : Array[@core.Vec2],
  second : Array[@core.Vec2],
) -> Double {
  if first.length() == 0 || second.length() == 0 {
    return 0.0
  }
  let mut total = 0.0
  for a in first {
    for b in second {
      total += squared_distance(a, b).sqrt()
    }
  }
  total / (first.length() * second.length()).to_double()
}

///|
/// 计算 Energy Distance，能够同时反映位置和形状差异。
pub fn energy_distance(
  target : Array[@core.Vec2],
  generated : Array[@core.Vec2],
) -> Double {
  if target.length() == 0 || generated.length() == 0 {
    return 0.0
  }
  let cross = average_pair_distance(target, generated)
  let target_self = average_pair_distance(target, target)
  let generated_self = average_pair_distance(generated, generated)
  2.0 * cross - target_self - generated_self
}

///|
fn rbf_kernel(a : @core.Vec2, b : @core.Vec2, bandwidth : Double) -> Double {
  let safe_bandwidth = if bandwidth <= 0.0 { 1.0 } else { bandwidth }
  @math.exp(-squared_distance(a, b) / (2.0 * safe_bandwidth * safe_bandwidth))
}

///|
fn average_kernel(
  first : Array[@core.Vec2],
  second : Array[@core.Vec2],
  bandwidth : Double,
) -> Double {
  if first.length() == 0 || second.length() == 0 {
    return 0.0
  }
  let mut total = 0.0
  for a in first {
    for b in second {
      total += rbf_kernel(a, b, bandwidth)
    }
  }
  total / (first.length() * second.length()).to_double()
}

///|
/// 计算 RBF 最大均值差异；带宽参数控制局部与全局相似度。
pub fn maximum_mean_discrepancy(
  target : Array[@core.Vec2],
  generated : Array[@core.Vec2],
  bandwidth : Double,
) -> Double {
  let xx = average_kernel(target, target, bandwidth)
  let yy = average_kernel(generated, generated, bandwidth)
  let xy = average_kernel(target, generated, bandwidth)
  let value = xx + yy - 2.0 * xy
  if value < 0.0 {
    0.0
  } else {
    value
  }
}

///|
/// 计算两个点集的局部多样性差异。
pub fn diversity_gap(
  target : Array[@core.Vec2],
  generated : Array[@core.Vec2],
) -> Double {
  (mean_nearest_neighbor_distance(target) -
  mean_nearest_neighbor_distance(generated)).abs()
}

///|
/// 使用相同边界和网格比较空间占用，避免不同自动边界导致的误判。
pub fn fixed_grid_intersection(
  target : Array[@core.Vec2],
  generated : Array[@core.Vec2],
  bins : Int,
  lower : @core.Vec2,
  upper : @core.Vec2,
) -> Double {
  let target_hist = Histogram2D::new(
    bins,
    bins,
    lower.x,
    upper.x,
    lower.y,
    upper.y,
  )
  let generated_hist = Histogram2D::new(
    bins,
    bins,
    lower.x,
    upper.x,
    lower.y,
    upper.y,
  )
  for point in target {
    target_hist.add(point)
  }
  for point in generated {
    generated_hist.add(point)
  }
  target_hist.intersection(generated_hist)
}

///|
/// 以多个指标组成一个比较结果，方便评审或自动化阈值判断。
pub fn compare(
  target : Array[@core.Vec2],
  generated : Array[@core.Vec2],
  bins : Int,
  bandwidth : Double,
) -> DistributionComparison {
  let (lower, upper) = bounding_box(target)
  let target_summary = summarize(target)
  let generated_summary = summarize(generated)
  {
    energy_distance: energy_distance(target, generated),
    mmd_rbf: maximum_mean_discrepancy(target, generated, bandwidth),
    histogram_intersection: fixed_grid_intersection(
      target, generated, bins, lower, upper,
    ),
    quality_score: quality_score(target, generated, bins),
    target_nn_distance: mean_nearest_neighbor_distance(target),
    generated_nn_distance: mean_nearest_neighbor_distance(generated),
    diversity_gap: (target_summary.duplicate_ratio -
    generated_summary.duplicate_ratio).abs(),
  }
}

///|
/// 将比较结果输出为单行 CSV。
pub fn comparison_csv(result : DistributionComparison) -> String {
  result.energy_distance.to_string() +
  "," +
  result.mmd_rbf.to_string() +
  "," +
  result.histogram_intersection.to_string() +
  "," +
  result.quality_score.to_string() +
  "," +
  result.target_nn_distance.to_string() +
  "," +
  result.generated_nn_distance.to_string() +
  "," +
  result.diversity_gap.to_string()
}

///|
/// 将比较结果输出为简洁 Markdown 卡片。
pub fn comparison_markdown(result : DistributionComparison) -> String {
  "| Metric | Value |\n|---|---:|\n" +
  "| Energy distance | " +
  result.energy_distance.to_string() +
  " |\n" +
  "| MMD (RBF) | " +
  result.mmd_rbf.to_string() +
  " |\n" +
  "| Histogram intersection | " +
  result.histogram_intersection.to_string() +
  " |\n" +
  "| Quality score | " +
  result.quality_score.to_string() +
  " |\n" +
  "| Target NN distance | " +
  result.target_nn_distance.to_string() +
  " |\n" +
  "| Generated NN distance | " +
  result.generated_nn_distance.to_string() +
  " |\n" +
  "| Diversity gap | " +
  result.diversity_gap.to_string() +
  " |\n"
}
