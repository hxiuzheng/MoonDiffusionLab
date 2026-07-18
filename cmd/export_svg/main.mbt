fn main {
  let rng = @core.Rng::new(seed=42UL)
  let moons = @dataset.sample_two_moons(120, noise=0.05, rng)
  let sched = @schedule.DiffusionSchedule::create(
    30,
    Linear(beta_start=0.001, beta_end=0.03),
  )
  let model_moons = @model.AnalyticalModel::new(moons, bandwidth=0.1)
  
  let svg_field = @visualize.render_svg_vector_field(
    model_moons,
    sched,
    10,
    grid_size=10,
  )
  println(svg_field)
}
