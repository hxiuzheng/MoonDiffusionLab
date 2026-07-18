///|
/// JSON 轨迹导出器：将扩散轨迹转换为紧凑的 JSON 格式，便于外部 Python 或 JS 程序读取。
pub fn export_trajectory_json(traj : @diffusion.Trajectory) -> String {
  let mut json = "{\"frames\": ["
  let num_frames = traj.num_frames()
  for i in 0..<num_frames {
    let t = traj.steps_recorded[i]
    let pts = traj.frames[i]
    json += "{\"step\": " + t.to_string() + ", \"points\": ["
    for j in 0..<pts.length() {
      let p = pts[j]
      json += "[" + p.x.to_string() + ", " + p.y.to_string() + "]"
      if j < pts.length() - 1 {
        json += ", "
      }
    }
    json += "]}"
    if i < num_frames - 1 {
      json += ", "
    }
  }
  json += "]}"
  json
}
