///|
/// 采样轨迹记录结构体，记录从 t = T-1 到 t = 0 过程中每隔一定间隔保存的云图状态
/// 用于后续生成 SVG 动画、终端 ASCII 渐变和数据统计分析
pub(all) struct Trajectory {
  steps_recorded : Array[Int]
  frames : Array[Array[@core.Vec2]]
} derive(Debug, Eq)

///|
/// 创建一个新的空轨迹记录器
pub fn Trajectory::new() -> Trajectory {
  { steps_recorded: [], frames: [] }
}

///|
/// 添加一帧采样云图到轨迹中
pub fn Trajectory::add_frame(
  self : Trajectory,
  step : Int,
  frame : Array[@core.Vec2],
) -> Unit {
  self.steps_recorded.push(step)
  // 复制一份云图保存
  let copy = Array::make(frame.length(), @core.Vec2::zero())
  for i in 0..<frame.length() {
    copy[i] = frame[i]
  }
  self.frames.push(copy)
}

///|
/// 获取轨迹总帧数
pub fn Trajectory::num_frames(self : Trajectory) -> Int {
  self.frames.length()
}
