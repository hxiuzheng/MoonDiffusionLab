///|
/// 计算 2D 点集的均值中心
pub fn mean_vec2(points : Array[Vec2]) -> Vec2 {
  if points.length() == 0 {
    return Vec2::zero()
  }
  let mut sum_x = 0.0
  let mut sum_y = 0.0
  for p in points {
    sum_x += p.x
    sum_y += p.y
  }
  let n = points.length().to_double()
  { x: sum_x / n, y: sum_y / n }
}

///|
/// 计算 2D 点集的方差 (x 方向方差与 y 方向方差)
pub fn variance_vec2(points : Array[Vec2]) -> Vec2 {
  if points.length() <= 1 {
    return Vec2::zero()
  }
  let mean = mean_vec2(points)
  let mut var_x = 0.0
  let mut var_y = 0.0
  for p in points {
    let dx = p.x - mean.x
    let dy = p.y - mean.y
    var_x += dx * dx
    var_y += dy * dy
  }
  let n = (points.length() - 1).to_double()
  { x: var_x / n, y: var_y / n }
}

///|
/// 计算两个 2D 点分布之间的估算切片 Wasserstein-1 (地球移动) 距离
/// 通过在主轴切片排序计算平均距离，用于快速评估扩散模型生成质量
pub fn sliced_wasserstein_approx(
  points_a : Array[Vec2],
  points_b : Array[Vec2],
) -> Double {
  let len = @cmp.minimum(points_a.length(), points_b.length())
  if len == 0 {
    return 0.0
  }

  // 提取 X 和 Y 坐标并在副本中排序
  let xs_a = Array::make(len, 0.0)
  let ys_a = Array::make(len, 0.0)
  let xs_b = Array::make(len, 0.0)
  let ys_b = Array::make(len, 0.0)

  for i in 0..<len {
    xs_a[i] = points_a[i].x
    ys_a[i] = points_a[i].y
    xs_b[i] = points_b[i].x
    ys_b[i] = points_b[i].y
  }

  xs_a.sort()
  ys_a.sort()
  xs_b.sort()
  ys_b.sort()

  let mut dist_x = 0.0
  let mut dist_y = 0.0
  for i in 0..<len {
    dist_x += (xs_a[i] - xs_b[i]).abs()
    dist_y += (ys_a[i] - ys_b[i]).abs()
  }

  let n = len.to_double()
  0.5 * (dist_x / n + dist_y / n)
}
