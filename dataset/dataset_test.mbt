///|
test "dataset generation count and statistics" {
  let rng = @core.Rng::new(seed=2026UL)

  let moons = sample_two_moons(100, rng)
  inspect(moons.length(), content="100")

  let roll = sample_swiss_roll(100, rng)
  inspect(roll.length(), content="100")

  let gmm = sample_gmm_ring(100, rng)
  inspect(gmm.length(), content="100")
  // GMM 环形分布中心均值应当靠近 (0, 0)
  let mean_gmm = @core.mean_vec2(gmm)
  inspect(mean_gmm.x.abs() < 0.5, content="true")
  inspect(mean_gmm.y.abs() < 0.5, content="true")

  let bimodal = sample_bimodal(100, rng)
  inspect(bimodal.length(), content="100")
  // 双峰分布中心均值 X 应该也靠近 0
  let mean_bi = @core.mean_vec2(bimodal)
  inspect(mean_bi.x.abs() < 0.5, content="true")
}
