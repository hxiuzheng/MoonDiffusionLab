fn main {
  let rng = @core.Rng::new(seed=42UL)
  let moons = @dataset.sample_two_moons(120, noise=0.05, rng)
  let sched = @schedule.DiffusionSchedule::create(
    30,
    Linear(beta_start=0.001, beta_end=0.03),
  )
  let model_moons = @model.AnalyticalModel::new(moons, bandwidth=0.1)
  let (_, ddpm_traj) = @diffusion.sample_ddpm_analytical(
    120,
    model_moons,
    sched,
    rng,
    record_interval=10,
  )
  
  let html_report = @visualize.generate_html_report(
    ddpm_traj,
    title="MoonDiffusionLab Two Moons Experiment",
  )
  println(html_report)
}
