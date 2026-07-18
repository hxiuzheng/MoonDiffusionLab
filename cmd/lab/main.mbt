///|
fn main {
  println(
    "====================================================================",
  )
  println(
    "   MoonDiffusionLab: 扩散模型原理实验工具箱 (1D/2D Toy Diffusion)   ",
  )
  println(
    "   Powered by Pure MoonBit | Pedagogical & High Visual Impact       ",
  )
  println(
    "====================================================================\n",
  )

  let rng = @core.Rng::new(seed=42UL)

  // 实验一：双月分布 (Two Moons) 前向加噪与 DDPM 随机去噪
  println("[Experiment 1] Two Moons Dataset - Forward Noising & DDPM Sampling")
  let moons = @dataset.sample_two_moons(120, noise=0.05, rng)
  println(
    @visualize.render_ascii_scatter(
      moons,
      width=50,
      height=18,
      title="Original Two Moons Dataset (t=0)",
    ),
  )

  let sched = @schedule.DiffusionSchedule::create(
    30,
    Linear(beta_start=0.001, beta_end=0.03),
  )
  let noised_mid = @diffusion.q_sample_batch(moons, 15, rng, sched)
  println(
    @visualize.render_ascii_scatter(
      noised_mid,
      width=50,
      height=18,
      title="Forward Noising Midpoint (t=15)",
    ),
  )

  let noised_end = @diffusion.q_sample_batch(moons, 29, rng, sched)
  println(
    @visualize.render_ascii_scatter(
      noised_end,
      width=50,
      height=18,
      title="Forward Noising End (t=29, Pure Gaussian)",
    ),
  )

  println("--> Starting DDPM Analytical Reverse Denoising Sampling...")
  let model_moons = @model.AnalyticalModel::new(moons, bandwidth=0.1)
  let (ddpm_samples, ddpm_traj) = @diffusion.sample_ddpm_analytical(
    120,
    model_moons,
    sched,
    rng,
    record_interval=10,
  )
  println(
    @visualize.render_ascii_scatter(
      ddpm_samples,
      width=50,
      height=18,
      title="DDPM Denoised Result (t=0)",
    ),
  )
  let wass_moons = @core.sliced_wasserstein_approx(ddpm_samples, moons)
  println(
    "    [Metric] Sliced Wasserstein Distance to Original: " +
    wass_moons.to_string() +
    "\n",
  )

  // 实验二：高斯环形分布 (GMM Ring) - DDIM 确定性加速采样
  println(
    "[Experiment 2] 8-Gaussians Ring Dataset - DDIM Deterministic Fast Sampling",
  )
  let gmm = @dataset.sample_gmm_ring(150, radius=2.0, noise=0.1, rng)
  println(
    @visualize.render_ascii_scatter(
      gmm,
      width=50,
      height=18,
      title="Original GMM Ring Dataset",
    ),
  )

  let sched_cosine = @schedule.DiffusionSchedule::create(30, Cosine(s=0.008))
  let model_gmm = @model.AnalyticalModel::new(gmm, bandwidth=0.1)
  println("--> Running DDIM 5-Step Fast Denoising Trajectory...")
  let (ddim_samples, _ddim_traj) = @diffusion.sample_ddim_analytical(
    150,
    model_gmm,
    sched_cosine,
    rng,
    num_steps=5,
  )
  println(
    @visualize.render_ascii_scatter(
      ddim_samples,
      width=50,
      height=18,
      title="DDIM 5-Step Fast Denoised Result",
    ),
  )
  let wass_gmm = @core.sliced_wasserstein_approx(ddim_samples, gmm)
  println(
    "    [Metric] Sliced Wasserstein Distance to Original: " +
    wass_gmm.to_string() +
    "\n",
  )

  // 解析命令行参数用于输出产物复现
  let args = @sys.get_cli_args()
  let mut mode = "cli"
  for i in 0..<args.length() {
    if args[i] == "html" {
      mode = "html"
    } else if args[i] == "svg" {
      mode = "svg"
    }
  }

  if mode == "html" {
    let html_report = @visualize.generate_html_report(
      ddpm_traj,
      title="MoonDiffusionLab Two Moons Experiment",
    )
    println(html_report)
    return
  }

  if mode == "svg" {
    let svg_field = @visualize.render_svg_vector_field(
      model_moons,
      sched,
      10,
      grid_size=10,
    )
    println(svg_field)
    return
  }

  // 实验三：双峰分布与 Euler ODE 轨迹
  println("[Experiment 3] Bimodal Distribution - Probability Flow Euler ODE")
  let bimodal = @dataset.sample_bimodal(100, dist=1.8, noise=0.15, rng)
  let model_bi = @model.AnalyticalModel::new(bimodal, bandwidth=0.1)
  let (euler_samples, _) = @diffusion.sample_euler_analytical(
    100,
    model_bi,
    sched,
    rng,
    num_steps=10,
  )
  println(
    @visualize.render_ascii_scatter(
      euler_samples,
      width=50,
      height=18,
      title="Euler ODE 10-Step Flow Result",
    ),
  )

  // 实验四：ToyMLP 采样整合
  println("[Experiment 4] ToyMLP Integration - DDPM Random Denoising")
  let toy_mlp = @model.ToyMLP::new(rng)
  let (mlp_samples, _) = @diffusion.sample_ddpm_mlp(
    100,
    toy_mlp,
    sched,
    rng,
    record_interval=10,
  )
  println(
    @visualize.render_ascii_scatter(
      mlp_samples,
      width=50,
      height=18,
      title="ToyMLP DDPM Denoised Result (Untrained)",
    ),
  )

  println(
    "\n====================================================================",
  )
  println(
    "   All diffusion experiments completed successfully!                ",
  )
  println("   Use `moon run cmd/lab -- html > demo.html` to generate HTML.   ")
  println(
    "====================================================================",
  )
}
