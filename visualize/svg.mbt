///|
/// SVG 渲染引擎：将散点云与 ODE 轨迹转换为标准可缩放矢量图形 XML 字符串
pub fn render_svg_scatter(
  points : Array[@core.Vec2],
  width? : Int = 600,
  height? : Int = 600,
  x_min? : Double = -3.0,
  x_max? : Double = 3.0,
  y_min? : Double = -3.0,
  y_max? : Double = 3.0,
  point_color? : String = "#00ffcc",
  bg_color? : String = "#121218",
) -> String {
  let mut svg = "<svg viewBox=\"0 0 " +
    width.to_string() +
    " " +
    height.to_string() +
    "\" xmlns=\"http://www.w3.org/2000/svg\" style=\"background-color: " +
    bg_color +
    "; font-family: monospace;\">\n"

  // 绘制坐标轴
  let cx0 = ((0.0 - x_min) / (x_max - x_min) * width.to_double()).to_int()
  let cy0 = height -
    ((0.0 - y_min) / (y_max - y_min) * height.to_double()).to_int()
  svg += "  <line x1=\"0\" y1=\"" +
    cy0.to_string() +
    "\" x2=\"" +
    width.to_string() +
    "\" y2=\"" +
    cy0.to_string() +
    "\" stroke=\"#333344\" stroke-width=\"1\" />\n"
  svg += "  <line x1=\"" +
    cx0.to_string() +
    "\" y1=\"0\" x2=\"" +
    cx0.to_string() +
    "\" y2=\"" +
    height.to_string() +
    "\" stroke=\"#333344\" stroke-width=\"1\" />\n"

  // 绘制散点
  for i in 0..<points.length() {
    let p = points[i]
    let sx = ((p.x - x_min) / (x_max - x_min) * width.to_double()).to_int()
    let sy = height -
      ((p.y - y_min) / (y_max - y_min) * height.to_double()).to_int()
    svg += "  <circle cx=\"" +
      sx.to_string() +
      "\" cy=\"" +
      sy.to_string() +
      "\" r=\"3\" fill=\"" +
      point_color +
      "\" opacity=\"0.7\" />\n"
  }
  svg += "</svg>"
  svg
}
