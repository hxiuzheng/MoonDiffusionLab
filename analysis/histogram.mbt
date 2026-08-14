///|
/// 2D 规则网格直方图，用于对生成分布进行可解释的空间比较。
/// 直方图不保存原始点，适合在报告和 CI 中传递紧凑的统计摘要。
pub(all) struct Histogram2D {
  bins_x : Int
  bins_y : Int
  min_x : Double
  max_x : Double
  min_y : Double
  max_y : Double
  counts : Array[Int]
} derive(Debug, Eq)

///|
/// 创建规则网格。非法的区间和 bin 数会被修正为安全的最小范围。
pub fn Histogram2D::new(
  bins_x : Int,
  bins_y : Int,
  min_x : Double,
  max_x : Double,
  min_y : Double,
  max_y : Double,
) -> Histogram2D {
  let safe_bins_x = if bins_x < 1 { 1 } else { bins_x }
  let safe_bins_y = if bins_y < 1 { 1 } else { bins_y }
  let safe_max_x = if max_x <= min_x { min_x + 1.0 } else { max_x }
  let safe_max_y = if max_y <= min_y { min_y + 1.0 } else { max_y }
  {
    bins_x: safe_bins_x,
    bins_y: safe_bins_y,
    min_x,
    max_x: safe_max_x,
    min_y,
    max_y: safe_max_y,
    counts: Array::make(safe_bins_x * safe_bins_y, 0),
  }
}

///|
fn clamp_bin(value : Double, lower : Double, upper : Double, bins : Int) -> Int {
  if value <= lower {
    0
  } else if value >= upper {
    bins - 1
  } else {
    let ratio = (value - lower) / (upper - lower)
    let index = (ratio * bins.to_double()).to_int()
    if index < 0 {
      0
    } else if index >= bins {
      bins - 1
    } else {
      index
    }
  }
}

///|
fn Histogram2D::index(self : Histogram2D, x : Double, y : Double) -> Int {
  let ix = clamp_bin(x, self.min_x, self.max_x, self.bins_x)
  let iy = clamp_bin(y, self.min_y, self.max_y, self.bins_y)
  iy * self.bins_x + ix
}

///|
/// 将一个点加入网格；区间外的点会被吸附到边界 bin，避免统计丢失。
pub fn Histogram2D::add(self : Histogram2D, point : @core.Vec2) -> Unit {
  let i = self.index(point.x, point.y)
  self.counts[i] += 1
}

///|
fn Histogram2D::sample_count(self : Histogram2D) -> Int {
  let mut total = 0
  for count in self.counts {
    total += count
  }
  total
}

///|
/// 从点集构造直方图，边界会根据点集自动推导。
pub fn Histogram2D::from_points(
  points : Array[@core.Vec2],
  bins_x : Int,
  bins_y : Int,
) -> Histogram2D {
  if points.length() == 0 {
    return Histogram2D::new(bins_x, bins_y, -1.0, 1.0, -1.0, 1.0)
  }
  let first = points[0]
  let mut min_x = first.x
  let mut max_x = first.x
  let mut min_y = first.y
  let mut max_y = first.y
  for point in points {
    if point.x < min_x {
      min_x = point.x
    }
    if point.x > max_x {
      max_x = point.x
    }
    if point.y < min_y {
      min_y = point.y
    }
    if point.y > max_y {
      max_y = point.y
    }
  }
  let padding_x = if max_x == min_x { 1.0 } else { (max_x - min_x) * 0.02 }
  let padding_y = if max_y == min_y { 1.0 } else { (max_y - min_y) * 0.02 }
  let hist = Histogram2D::new(
    bins_x,
    bins_y,
    min_x - padding_x,
    max_x + padding_x,
    min_y - padding_y,
    max_y + padding_y,
  )
  for point in points {
    hist.add(point)
  }
  hist
}

///|
/// 返回某个 bin 的原始计数。
pub fn Histogram2D::count(self : Histogram2D, ix : Int, iy : Int) -> Int {
  if ix < 0 || iy < 0 || ix >= self.bins_x || iy >= self.bins_y {
    0
  } else {
    self.counts[iy * self.bins_x + ix]
  }
}

///|
/// 返回某个 bin 的概率质量。
pub fn Histogram2D::density(self : Histogram2D, ix : Int, iy : Int) -> Double {
  let total = self.sample_count()
  if total == 0 {
    0.0
  } else {
    self.count(ix, iy).to_double() / total.to_double()
  }
}

///|
/// 返回全部 bin 的概率总和，用于验证统计守恒。
pub fn Histogram2D::total_density(self : Histogram2D) -> Double {
  let mut total = 0.0
  for iy in 0..<self.bins_y {
    for ix in 0..<self.bins_x {
      total += self.density(ix, iy)
    }
  }
  total
}

///|
/// 计算离散分布熵，衡量样本是否集中在少数网格中。
pub fn Histogram2D::entropy(self : Histogram2D) -> Double {
  let mut result = 0.0
  for iy in 0..<self.bins_y {
    for ix in 0..<self.bins_x {
      let p = self.density(ix, iy)
      if p > 0.0 {
        result -= p * @math.ln(p)
      }
    }
  }
  result
}

///|
/// 计算两个相同网格的分布交集；交集越接近 1，空间覆盖越一致。
pub fn Histogram2D::intersection(
  self : Histogram2D,
  other : Histogram2D,
) -> Double {
  if self.bins_x != other.bins_x || self.bins_y != other.bins_y {
    return 0.0
  }
  let mut value = 0.0
  for iy in 0..<self.bins_y {
    for ix in 0..<self.bins_x {
      let a = self.density(ix, iy)
      let b = other.density(ix, iy)
      value += if a < b { a } else { b }
    }
  }
  value
}

///|
/// 计算 Pearson 卡方距离，适合发现局部模式缺失。
pub fn Histogram2D::chi_square(
  self : Histogram2D,
  other : Histogram2D,
) -> Double {
  if self.bins_x != other.bins_x || self.bins_y != other.bins_y {
    return 0.0
  }
  let mut result = 0.0
  for iy in 0..<self.bins_y {
    for ix in 0..<self.bins_x {
      let a = self.density(ix, iy)
      let b = other.density(ix, iy)
      let denominator = a + b
      if denominator > 0.0 {
        let delta = a - b
        result += delta * delta / denominator
      }
    }
  }
  result
}

///|
/// 将直方图导出为长表 CSV，便于 pandas、R 或电子表格读取。
pub fn Histogram2D::to_csv(self : Histogram2D) -> String {
  let mut out = "ix,iy,count,density\n"
  for iy in 0..<self.bins_y {
    for ix in 0..<self.bins_x {
      out += ix.to_string() +
        "," +
        iy.to_string() +
        "," +
        self.count(ix, iy).to_string() +
        "," +
        self.density(ix, iy).to_string() +
        "\n"
    }
  }
  out
}

///|
/// 用字符热图快速查看二维分布覆盖，字符越靠后表示密度越高。
pub fn Histogram2D::to_ascii(self : Histogram2D) -> String {
  let shades = [' ', '.', ':', '-', '=', '+', '*', '#', '%', '@']
  let mut max_count = 0
  for count in self.counts {
    if count > max_count {
      max_count = count
    }
  }
  let mut out = ""
  for iy in 0..<self.bins_y {
    for ix in 0..<self.bins_x {
      let count = self.count(ix, iy)
      let shade_index = if max_count == 0 {
        0
      } else {
        count * (shades.length() - 1) / max_count
      }
      out += shades[shade_index].to_string()
    }
    out += "\n"
  }
  out
}
