///|
/// 生成经典的 2D 双月分布 (Two Moons) 数据集
/// 参数：
/// - count: 生成样本点总数量
/// - noise: 添加的高斯噪声标准差（默认 0.05）
/// - rng: 可复现随机数生成器
pub fn sample_two_moons(
  count : Int,
  noise? : Double = 0.05,
  rng : @core.Rng,
) -> Array[@core.Vec2] {
  let points = Array::make(count, @core.Vec2::zero())
  let half = count / 2
  for i in 0..<half {
    let theta = rng.next_double() * @math.PI
    let x = @math.cos(theta) + rng.next_normal(std=noise)
    let y = @math.sin(theta) + rng.next_normal(std=noise)
    points[i] = @core.Vec2::new(x, y)
  }
  for i in half..<count {
    let theta = rng.next_double() * @math.PI
    let x = 1.0 - @math.cos(theta) + rng.next_normal(std=noise)
    let y = 0.5 - @math.sin(theta) + rng.next_normal(std=noise)
    points[i] = @core.Vec2::new(x, y)
  }
  points
}
