///|
/// 控制台 2D ASCII 字符画云图渲染器
/// 将 2D 散点云映射到字符网格上，依据单元格内散点密度选择渐变字符 [' ', '.', '+', '*', '#', '@']
pub fn render_ascii_scatter(
  points : Array[@core.Vec2],
  width? : Int = 60,
  height? : Int = 30,
  x_min? : Double = -3.0,
  x_max? : Double = 3.0,
  y_min? : Double = -3.0,
  y_max? : Double = 3.0,
  title? : String = "Diffusion Scatter Plot",
) -> String {
  let grid = Array::make(width * height, 0)
  let x_range = x_max - x_min
  let y_range = y_max - y_min

  for i in 0..<points.length() {
    let p = points[i]
    if p.x >= x_min && p.x < x_max && p.y >= y_min && p.y < y_max {
      let gx = ((p.x - x_min) / x_range * width.to_double()).to_int()
      // 控制台 Y 轴向下，因此翻转 Y 坐标
      let gy = height -
        1 -
        ((p.y - y_min) / y_range * height.to_double()).to_int()
      let idx = gy * width + gx
      if idx >= 0 && idx < width * height {
        grid[idx] = grid[idx] + 1
      }
    }
  }

  let chars = [' ', '.', '+', '*', '#', '@']
  let mut out = "=== " + title + " ===\n"
  out += "+" + String::make(width, '-') + "+\n"

  for r in 0..<height {
    out += "|"
    for c in 0..<width {
      let count = grid[r * width + c]
      let char_idx = if count >= 5 { 5 } else { count }
      out += chars[char_idx].to_string()
    }
    out += "|\n"
  }
  out += "+" + String::make(width, '-') + "+\n"
  out
}
