///|
/// HTML 交互式报告引擎：生成包含 CSS 样式与多帧 SVG 对比展示的静态网页报告
/// 可用于一键生成生成模型教学实验实验报告与演示页面
pub fn generate_html_report(
  traj : @diffusion.Trajectory,
  title? : String = "MoonDiffusionLab Experiment Report",
) -> String {
  let mut html = "<!DOCTYPE html>\n<html>\n<head>\n  <meta charset=\"utf-8\">\n  <title>" +
    title +
    "</title>\n"
  html += "  <style>\n    body { background: #0f0f13; color: #e0e0e0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 40px; }\n"
  html += "    h1 { color: #00ffcc; text-align: center; font-weight: 300; letter-spacing: 2px; }\n"
  html += "    .grid { display: flex; flex-wrap: wrap; justify-content: center; gap: 20px; margin-top: 30px; }\n"
  html += "    .card { background: #1a1a24; border: 1px solid #2a2a3a; border-radius: 12px; padding: 15px; width: 300px; box-shadow: 0 8px 24px rgba(0,0,0,0.5); text-align: center; transition: transform 0.2s; }\n"
  html += "    .card:hover { transform: translateY(-5px); border-color: #00ffcc; }\n"
  html += "    .step-label { font-size: 14px; color: #8888a0; margin-bottom: 10px; font-family: monospace; }\n"
  html += "  </style>\n</head>\n<body>\n"
  html += "  <h1>" + title + "</h1>\n  <div class=\"grid\">\n"

  let num_frames = traj.num_frames()
  for i in 0..<num_frames {
    let step_num = traj.steps_recorded[i]
    let frame_points = traj.frames[i]
    let svg_str = render_svg_scatter(
      frame_points,
      width=280,
      height=280,
      point_color="#00ffcc",
      bg_color="#121218",
    )

    html += "    <div class=\"card\">\n"
    html += "      <div class=\"step-label\">Step t = " +
      step_num.to_string() +
      "</div>\n"
    html += "      " + svg_str + "\n"
    html += "    </div>\n"
  }

  html += "  </div>\n</body>\n</html>"
  html
}
