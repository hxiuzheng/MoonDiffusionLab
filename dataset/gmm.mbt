///|
/// 生成环形高斯混合分布 (8-Gaussians Ring / GMM)
/// 扩散模型经典 Benchmark 数据集：8 个高斯环绕在半径为 2.0 的圆周上
pub fn sample_gmm_ring(
  count : Int,
  radius? : Double = 2.0,
  noise? : Double = 0.1,
  rng : @core.Rng,
) -> Array[@core.Vec2] {
  let points = Array::make(count, @core.Vec2::zero())
  let num_clusters = 8
  for i in 0..<count {
    let cluster = (rng.next_uint64() % 8UL).to_int()
    let angle = cluster.to_double() * 2.0 * @math.PI / num_clusters.to_double()
    let center_x = radius * @math.cos(angle)
    let center_y = radius * @math.sin(angle)
    let x = center_x + rng.next_normal(std=noise)
    let y = center_y + rng.next_normal(std=noise)
    points[i] = @core.Vec2::new(x, y)
  }
  points
}
