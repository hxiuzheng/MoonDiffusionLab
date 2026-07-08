///|
/// DDIM (Denoising Diffusion Implicit Models) 加速确定性采样器
/// 通过构建非马尔可夫前向过程，允许在大大减少采样步数（例如 10 步甚至 5 步）的情况下，
/// 依然利用 ODE 轨迹以确定的方式快速生成高质量散点云
pub fn sample_ddim_analytical(
  count : Int,
  model : @model.AnalyticalModel,
  sched : @schedule.DiffusionSchedule,
  rng : @core.Rng,
  num_steps? : Int = 10,
) -> (Array[@core.Vec2], Trajectory) {
  let len = count
  let mut x = Array::make(len, @core.Vec2::zero())
  for i in 0..<len {
    x[i] = rng.next_vec2_normal()
  }

  let traj = Trajectory::new()
  let total_steps = sched.steps
  let step_size = if num_steps <= 0 { 1 } else { total_steps / num_steps }

  let mut current_t = total_steps - 1
  traj.add_frame(current_t, x)

  for step_idx in 0..<num_steps {
    let t = current_t
    let prev_t = if step_idx == num_steps - 1 { 0 } else { t - step_size }

    let alpha_bar_t = sched.get_alpha_bar(t)
    let alpha_bar_prev = sched.get_alpha_bar(prev_t)
    let sqrt_alpha_bar_t = alpha_bar_t.sqrt()
    let sqrt_alpha_bar_prev = alpha_bar_prev.sqrt()
    let sqrt_one_minus_alpha_bar_t = sched.get_sqrt_one_minus_alpha_bar(t)
    let sqrt_one_minus_alpha_bar_prev = (1.0 - alpha_bar_prev).sqrt()

    let next_x = Array::make(len, @core.Vec2::zero())
    for i in 0..<len {
      let x_t = x[i]
      let eps = model.predict_noise(x_t, t, sched)
      // 估计 x_0
      let pred_x0 = if sqrt_alpha_bar_t < 1.0e-10 {
        @core.Vec2::zero()
      } else {
        (x_t - eps.scale(sqrt_one_minus_alpha_bar_t)).div_scalar(
          sqrt_alpha_bar_t,
        )
      }
      // 确定性推导 x_{prev_t} = sqrt(alpha_bar_prev) * pred_x0 + sqrt(1 - alpha_bar_prev) * eps
      next_x[i] = pred_x0.scale(sqrt_alpha_bar_prev) +
        eps.scale(sqrt_one_minus_alpha_bar_prev)
    }
    x = next_x
    current_t = prev_t
    traj.add_frame(current_t, x)
  }
  (x, traj)
}
