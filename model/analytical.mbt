///|
/// 分析式噪声预测模型 (Analytical Noise / Score Predictor)
/// 基于数据集真实先验分布（如 GMM 聚类中心或样本点云），利用贝叶斯公式直接计算后验期期望 E[x_0 | x_t]
/// 从而得出理论最优的预测噪声 epsilon = (x_t - sqrt(alpha_bar) * E[x_0 | x_t]) / sqrt(1 - alpha_bar)
pub(all) struct AnalyticalModel {
  dataset : Array[@core.Vec2]
  bandwidth : Double // 样本平滑带宽，默认 0.1
} derive(Debug, Eq)

///|
/// 创建基于数据集点云的分析式模型
pub fn AnalyticalModel::new(
  dataset : Array[@core.Vec2],
  bandwidth? : Double = 0.1,
) -> AnalyticalModel {
  { dataset, bandwidth }
}

///|
/// 预测给定加噪状态 x_t 和时间步 t 下的噪声向量 epsilon
pub fn AnalyticalModel::predict_noise(
  self : AnalyticalModel,
  x_t : @core.Vec2,
  t : Int,
  sched : @schedule.DiffusionSchedule,
) -> @core.Vec2 {
  let sqrt_alpha_bar = sched.get_sqrt_alpha_bar(t)
  let sqrt_one_minus_alpha_bar = sched.get_sqrt_one_minus_alpha_bar(t)
  let var_t = sqrt_one_minus_alpha_bar * sqrt_one_minus_alpha_bar +
    self.bandwidth * self.bandwidth

  let len = self.dataset.length()
  if len == 0 {
    return @core.Vec2::zero()
  }

  // 为了防止浮点指数下溢或溢出，找最大对数权重减去
  let log_weights = Array::make(len, 0.0)
  let mut max_log_w = -1.0e30
  for i in 0..<len {
    let x_0 = self.dataset[i]
    let mean_t = x_0.scale(sqrt_alpha_bar)
    let dist = x_t.dist(mean_t)
    let dist_sq = dist * dist
    let log_w = -0.5 * dist_sq / var_t
    log_weights[i] = log_w
    if log_w > max_log_w {
      max_log_w = log_w
    }
  }

  let mut sum_w = 0.0
  let mut sum_x0 = @core.Vec2::zero()
  for i in 0..<len {
    let w = @math.exp(log_weights[i] - max_log_w)
    sum_w += w
    sum_x0 = sum_x0 + self.dataset[i].scale(w)
  }

  let e_x0 = sum_x0.div_scalar(sum_w)
  // epsilon = (x_t - sqrt(alpha_bar) * E[x_0]) / sqrt(1 - alpha_bar)
  if sqrt_one_minus_alpha_bar < 1.0e-10 {
    @core.Vec2::zero()
  } else {
    (x_t - e_x0.scale(sqrt_alpha_bar)).div_scalar(sqrt_one_minus_alpha_bar)
  }
}
