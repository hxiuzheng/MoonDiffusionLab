///|
test "ascii scatter plot rendering" {
  let pts = [
    @core.Vec2::new(0.0, 0.0),
    @core.Vec2::new(1.0, 1.0),
    @core.Vec2::new(-1.0, -1.0),
  ]
  let ascii = render_ascii_scatter(pts, width=20, height=10, title="Test Plot")
  inspect(ascii.contains("=== Test Plot ==="), content="true")
  inspect(ascii.contains("+--------------------+"), content="true")
}

///|
test "svg scatter and vector field rendering" {
  let pts = [@core.Vec2::new(0.5, 0.5)]
  let svg_pts = render_svg_scatter(pts, width=200, height=200)
  inspect(svg_pts.contains("<svg viewBox="), content="true")
  inspect(svg_pts.contains("<circle cx="), content="true")

  let dataset = [@core.Vec2::new(1.0, 1.0)]
  let model = @model.AnalyticalModel::new(dataset, bandwidth=0.1)
  let sched = @schedule.DiffusionSchedule::create(
    10,
    Linear(beta_start=0.001, beta_end=0.02),
  )
  let svg_field = render_svg_vector_field(model, sched, 5, grid_size=5)
  inspect(svg_field.contains("<line x1="), content="true")
}

///|
test "html report generation" {
  let traj = @diffusion.Trajectory::new()
  traj.add_frame(10, [@core.Vec2::new(0.0, 0.0)])
  traj.add_frame(0, [@core.Vec2::new(1.0, 1.0)])

  let html = generate_html_report(traj, title="Test Report")
  inspect(html.contains("<!DOCTYPE html>"), content="true")
  inspect(html.contains("Step t = 10"), content="true")
  inspect(html.contains("Step t = 0"), content="true")
}
