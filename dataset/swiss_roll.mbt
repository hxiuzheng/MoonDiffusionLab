///|
/// 生成 2D 瑞士卷分布 (Swiss Roll) 数据集
/// 模拟复杂流形结构，检验扩散模型对螺旋拓扑的重建能力
pub fn sample_swiss_roll(
  count : Int,
  noise? : Double = 0.05,
  rng : @core.Rng,
) -> Array[@core.Vec2] {
  let points = Array::make(count, @core.Vec2::zero())
  for i in 0..<count {
    // theta 从 1.5*PI 到 4.5*PI (3 个半圆周)
    let theta = 1.5 * @math.PI + rng.next_double() * 3.0 * @math.PI
    let r = theta / (4.5 * @math.PI) * 2.0 // 半径在 [0.66, 2.0] 递增
    let x = r * @math.cos(theta) + rng.next_normal(std=noise)
    let y = r * @math.sin(theta) + rng.next_normal(std=noise)
    points[i] = @core.Vec2::new(x, y)
  }
  points
}
