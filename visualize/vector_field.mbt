///|
/// ODE 评分场 / 漂移场可视化渲染器
/// 在网格点上采样模型预测的 Score/Drift 向量，并绘制带有箭头的 SVG 流场图
pub fn render_svg_vector_field(
  model : @model.AnalyticalModel,
  sched : @schedule.DiffusionSchedule,
  t : Int,
  grid_size? : Int = 15,
  width? : Int = 600,
  height? : Int = 600,
  x_min? : Double = -3.0,
  x_max? : Double = 3.0,
  y_min? : Double = -3.0,
  y_max? : Double = 3.0,
) -> String {
  let mut svg = "<svg viewBox=\"0 0 " +
    width.to_string() +
    " " +
    height.to_string() +
    "\" xmlns=\"http://www.w3.org/2000/svg\" style=\"background-color: #121218;\">\n"

  let step_x = (x_max - x_min) / grid_size.to_double()
  let step_y = (y_max - y_min) / grid_size.to_double()

  for r in 0..<=grid_size {
    for c in 0..<=grid_size {
      let x_val = x_min + c.to_double() * step_x
      let y_val = y_min + r.to_double() * step_y
      let pos = @core.Vec2::new(x_val, y_val)

      let eps = model.predict_noise(pos, t, sched)
      // Drift approx: -eps
      let drift = eps.scale(-0.3)

      let sx1 = ((x_val - x_min) / (x_max - x_min) * width.to_double()).to_int()
      let sy1 = height -
        ((y_val - y_min) / (y_max - y_min) * height.to_double()).to_int()

      let x2_val = x_val + drift.x
      let y2_val = y_val + drift.y
      let sx2 = ((x2_val - x_min) / (x_max - x_min) * width.to_double()).to_int()
      let sy2 = height -
        ((y2_val - y_min) / (y_max - y_min) * height.to_double()).to_int()

      svg += "  <line x1=\"" +
        sx1.to_string() +
        "\" y1=\"" +
        sy1.to_string() +
        "\" x2=\"" +
        sx2.to_string() +
        "\" y2=\"" +
        sy2.to_string() +
        "\" stroke=\"#ff3366\" stroke-width=\"1.5\" opacity=\"0.8\" />\n"
      svg += "  <circle cx=\"" +
        sx1.to_string() +
        "\" cy=\"" +
        sy1.to_string() +
        "\" r=\"1.5\" fill=\"#ffffff\" opacity=\"0.5\" />\n"
    }
  }
  svg += "</svg>"
  svg
}
