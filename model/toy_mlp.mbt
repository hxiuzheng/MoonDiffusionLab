///|
/// 轻量级 MoonBit 原生多层感知机 (Toy MLP)，用于演示参数化扩散模型前向推理
/// 包含 2 个隐藏层，使用 SiLU (Swish) 激活函数与时间嵌入 (Time Embedding)
pub(all) struct ToyMLP {
  w1 : @core.Matrix // 16 x 3 (x, y, t_emb)
  b1 : Array[Double] // 16
  w2 : @core.Matrix // 16 x 16
  b2 : Array[Double] // 16
  w3 : @core.Matrix // 2 x 16
  b3 : Array[Double] // 2
} derive(Debug, Eq)

///|
/// 使用伪随机数生成器初始化 MLP 权重参数 (Xavier 初始化)
pub fn ToyMLP::new(rng : @core.Rng) -> ToyMLP {
  let w1 = @core.Matrix::new(16, 3)
  let b1 = Array::make(16, 0.0)
  for r in 0..<16 {
    for c in 0..<3 {
      w1.set(r, c, rng.next_normal(std=0.5))
    }
    b1[r] = rng.next_normal(std=0.1)
  }

  let w2 = @core.Matrix::new(16, 16)
  let b2 = Array::make(16, 0.0)
  for r in 0..<16 {
    for c in 0..<16 {
      w2.set(r, c, rng.next_normal(std=0.25))
    }
    b2[r] = rng.next_normal(std=0.1)
  }

  let w3 = @core.Matrix::new(2, 16)
  let b3 = Array::make(2, 0.0)
  for r in 0..<2 {
    for c in 0..<16 {
      w3.set(r, c, rng.next_normal(std=0.25))
    }
    b3[r] = 0.0
  }

  { w1, b1, w2, b2, w3, b3 }
}

///|
/// SiLU / Swish 激活函数: x / (1 + exp(-x))
fn silu(x : Double) -> Double {
  x / (1.0 + @math.exp(-x))
}

///|
/// MLP 前向推理：预测给定位点和时间步下的噪声向量
pub fn ToyMLP::predict(self : ToyMLP, x : @core.Vec2, t : Double) -> @core.Vec2 {
  // 输入层: [x.x, x.y, t]
  let input = [x.x, x.y, t]

  // 第一层: h1 = silu(w1 * input + b1)
  let h1 = Array::make(16, 0.0)
  for r in 0..<16 {
    let mut val = self.b1[r]
    for c in 0..<3 {
      val += self.w1.get(r, c) * input[c]
    }
    h1[r] = silu(val)
  }

  // 第二层: h2 = silu(w2 * h1 + b2)
  let h2 = Array::make(16, 0.0)
  for r in 0..<16 {
    let mut val = self.b2[r]
    for c in 0..<16 {
      val += self.w2.get(r, c) * h1[c]
    }
    h2[r] = silu(val)
  }

  // 输出层: out = w3 * h2 + b3
  let out = Array::make(2, 0.0)
  for r in 0..<2 {
    let mut val = self.b3[r]
    for c in 0..<16 {
      val += self.w3.get(r, c) * h2[c]
    }
    out[r] = val
  }

  @core.Vec2::new(out[0], out[1])
}
