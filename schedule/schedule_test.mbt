///|
test "linear schedule properties" {
  let sched = DiffusionSchedule::create(
    100,
    Linear(beta_start=0.0001, beta_end=0.02),
  )
  inspect(sched.steps, content="100")

  // 检查 beta_0 和 beta_99
  inspect((sched.betas[0] - 0.0001).abs() < 1.0e-10, content="true")
  inspect((sched.betas[99] - 0.02).abs() < 1.0e-10, content="true")

  // 检查 alphas_cumprod 单调递减且勾股恒等式成立
  let mut monotonic = true
  for i in 1..<100 {
    if sched.alphas_cumprod[i] >= sched.alphas_cumprod[i - 1] {
      monotonic = false
    }
    let s1 = sched.sqrt_alphas_cumprod[i]
    let s2 = sched.sqrt_one_minus_alphas_cumprod[i]
    let pythagoras = s1 * s1 + s2 * s2
    if (pythagoras - 1.0).abs() > 1.0e-10 {
      monotonic = false
    }
  }
  inspect(monotonic, content="true")
}

///|
test "cosine schedule properties" {
  let sched = DiffusionSchedule::create(50, Cosine(s=0.008))
  inspect(sched.steps, content="50")

  // 余弦调度末端累乘 alpha 应该非常接近 0
  let final_alpha_bar = sched.alphas_cumprod[49]
  inspect(final_alpha_bar < 0.05, content="true")
}

///|
test "sigmoid schedule properties" {
  let sched = DiffusionSchedule::create(
    50,
    Sigmoid(beta_start=0.0001, beta_end=0.02),
  )
  inspect(sched.steps, content="50")
  inspect(sched.betas[0] < sched.betas[25], content="true")
  inspect(sched.betas[25] < sched.betas[49], content="true")
}

///|
test "metrics: schedule variance and boundary assertions" {
  let sched = DiffusionSchedule::create(
    100,
    Linear(beta_start=0.0001, beta_end=0.02),
  )
  let mut sum_beta = 0.0
  for b in sched.betas {
    sum_beta = sum_beta + b
  }
  let mean_beta = sum_beta / 100.0
  inspect(mean_beta > 0.005 && mean_beta < 0.015, content="true")
  inspect(sched.alphas_cumprod[99] > 0.0, content="true")
  inspect(sched.alphas_cumprod[99] < 1.0, content="true")
}
