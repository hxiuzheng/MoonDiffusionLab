///|
/// 生成余弦平滑噪声调度表 (Nichol & Dhariwal 2021)
/// 避免线性调度在末端噪声增加过快的问题，适合小数据集与 Toy 模型
pub fn make_cosine_betas(steps : Int, s? : Double = 0.008) -> Array[Double] {
  let betas = Array::make(steps, 0.0)
  let max_val = steps.to_double()
  let f_0 = @math.cos(s / (1.0 + s) * (@math.PI / 2.0))
  let f_0_sq = f_0 * f_0

  let mut prev_alpha_bar = 1.0
  for i in 0..<steps {
    let t = (i + 1).to_double() / max_val
    let f_t = @math.cos((t + s) / (1.0 + s) * (@math.PI / 2.0))
    let alpha_bar = f_t * f_t / f_0_sq
    let mut beta = 1.0 - alpha_bar / prev_alpha_bar
    // 限制 beta 最大值为 0.999 防止数值不稳定
    if beta > 0.999 {
      beta = 0.999
    }
    if beta < 0.00001 {
      beta = 0.00001
    }
    betas[i] = beta
    prev_alpha_bar = alpha_bar
  }
  betas
}
