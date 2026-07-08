///|
/// 前向扩散加噪过程 q(x_t | x_0) = sqrt(alpha_bar_t) * x_0 + sqrt(1 - alpha_bar_t) * epsilon
/// 模拟信息在物理时间推移下被高斯噪声逐步淹没的过程
pub fn q_sample(
  x_0 : @core.Vec2,
  t : Int,
  noise : @core.Vec2,
  sched : @schedule.DiffusionSchedule,
) -> @core.Vec2 {
  let sqrt_alpha_bar = sched.get_sqrt_alpha_bar(t)
  let sqrt_one_minus_alpha_bar = sched.get_sqrt_one_minus_alpha_bar(t)
  x_0.scale(sqrt_alpha_bar) + noise.scale(sqrt_one_minus_alpha_bar)
}

///|
/// 批量前向扩散加噪：对整个数据集在指定步数 t 叠加噪声
pub fn q_sample_batch(
  dataset : Array[@core.Vec2],
  t : Int,
  rng : @core.Rng,
  sched : @schedule.DiffusionSchedule,
) -> Array[@core.Vec2] {
  let len = dataset.length()
  let out = Array::make(len, @core.Vec2::zero())
  for i in 0..<len {
    let noise = rng.next_vec2_normal()
    out[i] = q_sample(dataset[i], t, noise, sched)
  }
  out
}

///|
/// 快捷演示：自动生成双月数据集并在时间步 t 叠加高斯噪声
pub fn demo_forward_two_moons(
  count : Int,
  t : Int,
  rng : @core.Rng,
  sched : @schedule.DiffusionSchedule,
) -> Array[@core.Vec2] {
  let data = @dataset.sample_two_moons(count, rng)
  q_sample_batch(data, t, rng, sched)
}
