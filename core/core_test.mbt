///|
test "vec2 math operations" {
  let v1 = Vec2::new(3.0, 4.0)
  let v2 = Vec2::new(1.0, 2.0)

  let sum = v1 + v2
  debug_inspect(
    sum,
    content=(
      #|{ x: 4, y: 6 }
    ),
  )

  let diff = v1 - v2
  debug_inspect(
    diff,
    content=(
      #|{ x: 2, y: 2 }
    ),
  )

  let scaled = v1.scale(2.0)
  debug_inspect(
    scaled,
    content=(
      #|{ x: 6, y: 8 }
    ),
  )

  let dot = v1.dot(v2)
  inspect(
    dot,
    content=(
      #|11
    ),
  )

  let norm = v1.norm()
  inspect(
    norm,
    content=(
      #|5
    ),
  )

  let norm_vec = v1.normalize()
  inspect(
    norm_vec.norm(),
    content=(
      #|1
    ),
  )
}

///|
test "matrix 2x2 matvec multiplication" {
  let mat = Matrix::new(2, 2)
  mat.set(0, 0, 2.0)
  mat.set(0, 1, 0.0)
  mat.set(1, 0, 0.0)
  mat.set(1, 1, 3.0)

  let v = Vec2::new(1.5, 2.0)
  let res = mat.matvec2(v)
  debug_inspect(
    res,
    content=(
      #|{ x: 3, y: 6 }
    ),
  )
}

///|
test "rng determinism and box-muller normal distribution" {
  let rng = Rng::new(seed=42UL)
  let n1 = rng.next_normal()
  let n2 = rng.next_normal()

  // 相同种子必须生成确定的数值序列
  let rng_ref = Rng::new(seed=42UL)
  inspect(rng_ref.next_normal() == n1, content="true")
  inspect(rng_ref.next_normal() == n2, content="true")

  // 采样 1000 个高斯随机点，验证均值接近 0.0，方差接近 1.0
  let samples = Array::make(1000, Vec2::zero())
  for i in 0..<1000 {
    samples[i] = rng.next_vec2_normal()
  }

  let mean = mean_vec2(samples)
  let variance = variance_vec2(samples)

  // 检查样本统计特性合理
  inspect(mean.x.abs() < 0.2, content="true")
  inspect(mean.y.abs() < 0.2, content="true")
  inspect((variance.x - 1.0).abs() < 0.3, content="true")
  inspect((variance.y - 1.0).abs() < 0.3, content="true")
}

///|
test "sliced wasserstein distance" {
  let p1 = [Vec2::new(0.0, 0.0), Vec2::new(1.0, 1.0), Vec2::new(2.0, 2.0)]
  let p2 = [Vec2::new(0.0, 0.0), Vec2::new(1.0, 1.0), Vec2::new(2.0, 2.0)]
  let p3 = [Vec2::new(1.0, 1.0), Vec2::new(2.0, 2.0), Vec2::new(3.0, 3.0)]

  let d_zero = sliced_wasserstein_approx(p1, p2)
  inspect(
    d_zero,
    content=(
      #|0
    ),
  )

  let d_shift = sliced_wasserstein_approx(p1, p3)
  inspect(
    d_shift,
    content=(
      #|1
    ),
  )
}

///|
test "bench: tensor normal generation throughput" {
  let rng = Rng::new(seed=12345UL)
  let samples = Array::make(500, Vec2::zero())
  for i in 0..<500 {
    samples[i] = rng.next_vec2_normal()
  }
  inspect(samples.length(), content="500")
}
