///|
/// 生成 1D/2D 双峰概率分布 (Bimodal Distribution)
/// 两个聚集点分别在 (-dist, 0) 和 (dist, 0)，测试扩散模型在多分支模式下的采样分布平衡性
pub fn sample_bimodal(
  count : Int,
  dist? : Double = 1.5,
  noise? : Double = 0.2,
  rng : @core.Rng,
) -> Array[@core.Vec2] {
  let points = Array::make(count, @core.Vec2::zero())
  for i in 0..<count {
    let is_right = rng.next_double() > 0.5
    let center_x = if is_right { dist } else { -dist }
    let x = center_x + rng.next_normal(std=noise)
    let y = rng.next_normal(std=noise * 0.5)
    points[i] = @core.Vec2::new(x, y)
  }
  points
}
