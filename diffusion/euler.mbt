///|
/// Euler 连续时间 ODE 采样器 (Probability Flow ODE)
/// 将扩散去噪过程表达为常微分方程，使用一阶欧拉积分快速仿真连续生成场
pub fn sample_euler_analytical(
  count : Int,
  model : @model.AnalyticalModel,
  sched : @schedule.DiffusionSchedule,
  rng : @core.Rng,
  num_steps? : Int = 15,
) -> (Array[@core.Vec2], Trajectory) {
  let len = count
  let mut x = Array::make(len, @core.Vec2::zero())
  for i in 0..<len {
    x[i] = rng.next_vec2_normal()
  }

  let traj = Trajectory::new()
  let total_steps = sched.steps
  let dt = if num_steps <= 0 {
    1.0
  } else {
    total_steps.to_double() / num_steps.to_double()
  }

  let mut current_t_val = (total_steps - 1).to_double()
  traj.add_frame(total_steps - 1, x)

  for _step in 0..<num_steps {
    let t_int = current_t_val.to_int()
    let t_idx = if t_int < 0 {
      0
    } else if t_int >= total_steps {
      total_steps - 1
    } else {
      t_int
    }

    let beta_t = sched.betas[t_idx]
    let sqrt_one_minus_alpha_bar = sched.get_sqrt_one_minus_alpha_bar(t_idx)

    let next_x = Array::make(len, @core.Vec2::zero())
    for i in 0..<len {
      let x_t = x[i]
      let eps = model.predict_noise(x_t, t_idx, sched)
      let score = if sqrt_one_minus_alpha_bar < 1.0e-10 {
        @core.Vec2::zero()
      } else {
        eps.div_scalar(-sqrt_one_minus_alpha_bar)
      }

      let drift = (x_t +
      score.scale(sqrt_one_minus_alpha_bar * sqrt_one_minus_alpha_bar)).scale(
        -0.5 * beta_t,
      )
      next_x[i] = x_t + drift.scale(dt)
    }
    x = next_x
    current_t_val -= dt
    let save_t = current_t_val.to_int()
    let save_idx = if save_t < 0 { 0 } else { save_t }
    traj.add_frame(save_idx, x)
  }
  (x, traj)
}
