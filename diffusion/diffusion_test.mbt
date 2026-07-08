///|
test "forward noising q_sample increases variance" {
  let rng = @core.Rng::new(seed=999UL)
  let orig = @dataset.sample_two_moons(100, rng)
  let sched = @schedule.DiffusionSchedule::create(
    50,
    Linear(beta_start=0.0001, beta_end=0.02),
  )

  let noised_t10 = q_sample_batch(orig, 10, rng, sched)
  let noised_t49 = q_sample_batch(orig, 49, rng, sched)
  let demo_t20 = demo_forward_two_moons(50, 20, rng, sched)

  inspect(noised_t10.length(), content="100")
  inspect(demo_t20.length(), content="50")

  // t=49 的点距离原点分布更广（接近纯高斯噪声）
  let var_orig = @core.variance_vec2(orig)
  let var_49 = @core.variance_vec2(noised_t49)

  inspect(var_49.x > var_orig.x, content="true")
  inspect(var_49.y > var_orig.y, content="true")
}

///|
test "ddpm sampling restores distribution" {
  let rng = @core.Rng::new(seed=111UL)
  let target_data = @dataset.sample_gmm_ring(50, rng)
  let model = @model.AnalyticalModel::new(target_data, bandwidth=0.1)
  let sched = @schedule.DiffusionSchedule::create(
    30,
    Linear(beta_start=0.001, beta_end=0.03),
  )

  let (samples, traj) = sample_ddpm_analytical(
    50,
    model,
    sched,
    rng,
    record_interval=10,
  )
  inspect(samples.length(), content="50")
  inspect(traj.num_frames() > 1, content="true")

  // 采样完成后的 Wasserstein 距离应当较小
  let dist = @core.sliced_wasserstein_approx(samples, target_data)
  inspect(dist < 1.5, content="true")
}

///|
test "ddim fast deterministic sampling" {
  let rng = @core.Rng::new(seed=222UL)
  let target_data = @dataset.sample_two_moons(50, rng)
  let model = @model.AnalyticalModel::new(target_data, bandwidth=0.1)
  let sched = @schedule.DiffusionSchedule::create(30, Cosine(s=0.008))

  let (samples, traj) = sample_ddim_analytical(
    50,
    model,
    sched,
    rng,
    num_steps=5,
  )
  inspect(samples.length(), content="50")
  inspect(traj.num_frames(), content="6")
}

///|
test "euler ode sampling" {
  let rng = @core.Rng::new(seed=333UL)
  let target_data = @dataset.sample_bimodal(50, rng)
  let model = @model.AnalyticalModel::new(target_data, bandwidth=0.1)
  let sched = @schedule.DiffusionSchedule::create(
    30,
    Linear(beta_start=0.001, beta_end=0.03),
  )

  let (samples, traj) = sample_euler_analytical(
    50,
    model,
    sched,
    rng,
    num_steps=5,
  )
  inspect(samples.length(), content="50")
  inspect(traj.num_frames(), content="6")
}
