///|
/// 生成线性噪声调度表（DDPM 标准策略）
/// 通常 beta_start = 0.0001, beta_end = 0.02
pub fn make_linear_betas(
  steps : Int,
  beta_start? : Double = 0.0001,
  beta_end? : Double = 0.02,
) -> Array[Double] {
  let betas = Array::make(steps, 0.0)
  if steps == 1 {
    betas[0] = beta_start
    return betas
  }
  let step_size = (beta_end - beta_start) / (steps - 1).to_double()
  for i in 0..<steps {
    betas[i] = beta_start + i.to_double() * step_size
  }
  betas
}
