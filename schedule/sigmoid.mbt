///|
/// 生成 Sigmoid 噪声调度表
/// 在中段迅速增加噪声，在两端变化平缓
pub fn make_sigmoid_betas(
  steps : Int,
  beta_start? : Double = 0.0001,
  beta_end? : Double = 0.02,
) -> Array[Double] {
  let betas = Array::make(steps, 0.0)
  if steps == 1 {
    betas[0] = beta_start
    return betas
  }
  for i in 0..<steps {
    let x = -6.0 + 12.0 * (i.to_double() / (steps - 1).to_double())
    let sig = 1.0 / (1.0 + @math.exp(-x))
    betas[i] = beta_start + (beta_end - beta_start) * sig
  }
  betas
}
