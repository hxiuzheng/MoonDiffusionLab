///|
/// DDPM (Denoising Diffusion Probabilistic Models) 随机去噪采样器
/// 从纯高斯随机噪声 N(0, I) 出发，通过 1/(sqrt(alpha_t)) * (x_t - (beta_t / sqrt(1 - alpha_bar_t)) * eps) + sigma_t * z
/// 逐层逆转扩散过程，复原出符合原始先验分布的数据集
pub fn sample_ddpm_analytical(
  count : Int,
  model : @model.AnalyticalModel,
  sched : @schedule.DiffusionSchedule,
  rng : @core.Rng,
  record_interval? : Int = 10,
) -> (Array[@core.Vec2], Trajectory) {
  let len = count
  let mut x = Array::make(len, @core.Vec2::zero())
  for i in 0..<len {
    x[i] = rng.next_vec2_normal()
  }

  let traj = Trajectory::new()
  traj.add_frame(sched.steps - 1, x)

  let steps = sched.steps
  for step_idx in 0..<steps {
    let t = steps - 1 - step_idx
    let alpha_t = sched.get_alpha(t)
    let beta_t = sched.betas[t]
    let sqrt_alpha_t = alpha_t.sqrt()
    let sqrt_one_minus_alpha_bar = sched.get_sqrt_one_minus_alpha_bar(t)
    let sigma_t = sched.posterior_variance[t].sqrt()

    let next_x = Array::make(len, @core.Vec2::zero())
    for i in 0..<len {
      let x_t = x[i]
      let eps = model.predict_noise(x_t, t, sched)
      // 计算均值 mu = 1/sqrt(alpha) * (x_t - (beta / sqrt(1 - alpha_bar)) * eps)
      let coeff = if sqrt_one_minus_alpha_bar < 1.0e-10 {
        0.0
      } else {
        beta_t / sqrt_one_minus_alpha_bar
      }
      let mu = (x_t - eps.scale(coeff)).div_scalar(sqrt_alpha_t)

      if t == 0 {
        next_x[i] = mu
      } else {
        let z = rng.next_vec2_normal()
        next_x[i] = mu + z.scale(sigma_t)
      }
    }
    x = next_x
    if t % record_interval == 0 || t == 0 {
      traj.add_frame(t, x)
    }
  }
  (x, traj)
}
