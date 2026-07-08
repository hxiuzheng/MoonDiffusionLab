///|
test "analytical model prediction" {
  let dataset = [@core.Vec2::new(1.0, 1.0), @core.Vec2::new(-1.0, -1.0)]
  let model = AnalyticalModel::new(dataset, bandwidth=0.1)
  let sched = @schedule.DiffusionSchedule::create(
    50,
    Linear(beta_start=0.0001, beta_end=0.02),
  )

  let x_t = @core.Vec2::new(0.8, 0.8)
  let noise = model.predict_noise(x_t, 10, sched)
  // 预测出的噪声不应当是零向量
  inspect(noise.norm() > 0.0, content="true")
}

///|
test "toy mlp forward inference" {
  let rng = @core.Rng::new(seed=123UL)
  let mlp = ToyMLP::new(rng)

  let x = @core.Vec2::new(0.5, -0.5)
  let out = mlp.predict(x, 0.5)
  // 检查神经网络有正常数值输出
  inspect(out.norm() < 100.0, content="true")
}
