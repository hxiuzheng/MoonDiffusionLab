///|
/// 可复现伪随机数生成器 (PCG32/XorShift 算法)，用于扩散模型加噪与采样过程的确定性控制
pub(all) struct Rng {
  mut state : UInt64
} derive(Debug, Eq)

///|
/// 初始化随机数生成器，默认种子 20260708
pub fn Rng::new(seed? : UInt64 = 20260708UL) -> Rng {
  let init_state = if seed == 0UL { 1UL } else { seed }
  { state: init_state }
}

///|
/// 生成下一个 UInt64 伪随机数 (XorShift64*)
pub fn Rng::next_uint64(self : Rng) -> UInt64 {
  let mut x = self.state
  x = x ^ (x << 13)
  x = x ^ (x >> 7)
  x = x ^ (x << 17)
  self.state = x
  x * 0x2545F4914F6CDD1DUL
}

///|
/// 生成 [0.0, 1.0) 区间内的均匀分布双精度浮点数
pub fn Rng::next_double(self : Rng) -> Double {
  let u = self.next_uint64() >> 11
  // 53 位浮点数精度转化
  let max_val = 9007199254740992.0 // 2^53
  u.to_double() / max_val
}

///|
/// 使用 Box-Muller 变换生成标准正态分布 N(0, 1) 浮点数
pub fn Rng::next_normal(
  self : Rng,
  mean? : Double = 0.0,
  std? : Double = 1.0,
) -> Double {
  let mut u1 = self.next_double()
  let u2 = self.next_double()
  // 防止 log(0)
  while u1 <= 1.0e-15 {
    u1 = self.next_double()
  }
  let z0 = (-2.0 * @math.ln(u1)).sqrt() * @math.cos(2.0 * @math.PI * u2)
  mean + z0 * std
}

///|
/// 生成 2D 独立同分布的高斯正态随机向量 N(mean, std^2 * I)
pub fn Rng::next_vec2_normal(
  self : Rng,
  mean? : Vec2 = Vec2::zero(),
  std? : Double = 1.0,
) -> Vec2 {
  let mut u1 = self.next_double()
  let u2 = self.next_double()
  while u1 <= 1.0e-15 {
    u1 = self.next_double()
  }
  let r = (-2.0 * @math.ln(u1)).sqrt()
  let theta = 2.0 * @math.PI * u2
  let z0 = r * @math.cos(theta)
  let z1 = r * @math.sin(theta)
  { x: mean.x + z0 * std, y: mean.y + z1 * std }
}
