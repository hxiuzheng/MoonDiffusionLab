///|
/// 点集的基础统计摘要，作为实验报告的稳定数据结构。
pub(all) struct DistributionSummary {
  count : Int
  mean : @core.Vec2
  variance : @core.Vec2
  minimum : @core.Vec2
  maximum : @core.Vec2
  duplicate_ratio : Double
} derive(Debug, Eq)

///|
/// 计算点集的最小包围盒。
pub fn bounding_box(points : Array[@core.Vec2]) -> (@core.Vec2, @core.Vec2) {
  if points.length() == 0 {
    return (@core.Vec2::zero(), @core.Vec2::zero())
  }
  let first = points[0]
  let mut min_x = first.x
  let mut max_x = first.x
  let mut min_y = first.y
  let mut max_y = first.y
  for point in points {
    if point.x < min_x {
      min_x = point.x
    }
    if point.x > max_x {
      max_x = point.x
    }
    if point.y < min_y {
      min_y = point.y
    }
    if point.y > max_y {
      max_y = point.y
    }
  }
  (@core.Vec2::new(min_x, min_y), @core.Vec2::new(max_x, max_y))
}

///|
/// 计算点集中完全重复点的比例，发现随机数或采样退化问题。
pub fn duplicate_ratio(
  points : Array[@core.Vec2],
  tolerance? : Double = 1.0e-9,
) -> Double {
  if points.length() <= 1 {
    return 0.0
  }
  let mut duplicate = 0
  for i in 0..<points.length() {
    let mut found = false
    for j in 0..<i {
      if points[i].dist(points[j]) <= tolerance {
        found = true
      }
    }
    if found {
      duplicate += 1
    }
  }
  duplicate.to_double() / points.length().to_double()
}

///|
/// 计算每个点到最近其他点的距离均值，用于观察样本坍缩和过度稀疏。
pub fn mean_nearest_neighbor_distance(points : Array[@core.Vec2]) -> Double {
  if points.length() <= 1 {
    return 0.0
  }
  let mut total = 0.0
  for i in 0..<points.length() {
    let mut nearest = 1.0e30
    for j in 0..<points.length() {
      if i != j {
        let distance = points[i].dist(points[j])
        if distance < nearest {
          nearest = distance
        }
      }
    }
    total += nearest
  }
  total / points.length().to_double()
}

///|
/// 计算给定轴的经验分位数，使用排序后的线性插值。
pub fn quantile_axis(
  points : Array[@core.Vec2],
  axis : Int,
  quantile : Double,
) -> Double {
  if points.length() == 0 {
    return 0.0
  }
  let values = Array::make(points.length(), 0.0)
  for i in 0..<points.length() {
    values[i] = if axis == 0 { points[i].x } else { points[i].y }
  }
  values.sort()
  let q = if quantile < 0.0 {
    0.0
  } else if quantile > 1.0 {
    1.0
  } else {
    quantile
  }
  let position = q * (values.length() - 1).to_double()
  let lower = position.to_int()
  let upper = if lower + 1 >= values.length() { lower } else { lower + 1 }
  let weight = position - lower.to_double()
  values[lower] * (1.0 - weight) + values[upper] * weight
}

///|
/// 返回一个点集的完整统计摘要。
pub fn summarize(points : Array[@core.Vec2]) -> DistributionSummary {
  let (minimum, maximum) = bounding_box(points)
  {
    count: points.length(),
    mean: @core.mean_vec2(points),
    variance: @core.variance_vec2(points),
    minimum,
    maximum,
    duplicate_ratio: duplicate_ratio(points),
  }
}

///|
/// 计算两个分布在均值、方差、包围盒和局部密度上的综合质量分数。
/// 分数范围约为 [0, 1]，越高表示越接近目标分布。
pub fn quality_score(
  target : Array[@core.Vec2],
  generated : Array[@core.Vec2],
  bins : Int,
) -> Double {
  if target.length() == 0 || generated.length() == 0 {
    return 0.0
  }
  let target_summary = summarize(target)
  let generated_summary = summarize(generated)
  let mean_gap = target_summary.mean.dist(generated_summary.mean)
  let variance_gap = target_summary.variance.dist(generated_summary.variance)
  let target_hist = Histogram2D::from_points(target, bins, bins)
  let generated_hist = Histogram2D::from_points(generated, bins, bins)
  let overlap = target_hist.intersection(generated_hist)
  let mean_term = 1.0 / (1.0 + mean_gap)
  let variance_term = 1.0 / (1.0 + variance_gap)
  let diversity_term = 1.0 - generated_summary.duplicate_ratio
  mean_term * 0.25 + variance_term * 0.25 + overlap * 0.4 + diversity_term * 0.1
}

///|
/// 生成面向报告的质量摘要文本。
pub fn summary_markdown(name : String, summary : DistributionSummary) -> String {
  "### " +
  name +
  "\n\n" +
  "| Metric | X | Y |\n|---|---:|---:|\n" +
  "| Mean | " +
  summary.mean.x.to_string() +
  " | " +
  summary.mean.y.to_string() +
  " |\n" +
  "| Variance | " +
  summary.variance.x.to_string() +
  " | " +
  summary.variance.y.to_string() +
  " |\n" +
  "| Minimum | " +
  summary.minimum.x.to_string() +
  " | " +
  summary.minimum.y.to_string() +
  " |\n" +
  "| Maximum | " +
  summary.maximum.x.to_string() +
  " | " +
  summary.maximum.y.to_string() +
  " |\n" +
  "| Duplicate ratio | " +
  summary.duplicate_ratio.to_string() +
  " | - |\n"
}
