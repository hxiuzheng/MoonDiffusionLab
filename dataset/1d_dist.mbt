///|
/// 生成 1D 均匀分布散点 (投影到 2D 上的 y=0 线)
pub fn sample_1d_uniform(
  count : Int,
  min_x? : Double = -2.0,
  max_x? : Double = 2.0,
  rng : @core.Rng,
) -> Array[@core.Vec2] {
  let out = Array::make(count, @core.Vec2::zero())
  let range = max_x - min_x
  for i in 0..<count {
    let u = rng.next_double()
    let x = min_x + u * range
    out[i] = @core.Vec2::new(x, 0.0)
  }
  out
}

///|
/// 生成 1D 高斯分布散点
pub fn sample_1d_gaussian(
  count : Int,
  mean? : Double = 0.0,
  std? : Double = 1.0,
  rng : @core.Rng,
) -> Array[@core.Vec2] {
  let out = Array::make(count, @core.Vec2::zero())
  for i in 0..<count {
    let g = rng.next_vec2_normal()
    let x = mean + g.x * std
    out[i] = @core.Vec2::new(x, 0.0)
  }
  out
}
