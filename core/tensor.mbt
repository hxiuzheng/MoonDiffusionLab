///|
/// 2D 向量结构体，用于二维扩散模型轨迹采样与数值计算
pub(all) struct Vec2 {
  x : Double
  y : Double
} derive(Debug, Eq)

///|
/// 创建一个新的 2D 向量
pub fn Vec2::new(x : Double, y : Double) -> Vec2 {
  { x, y }
}

///|
/// 零向量
pub fn Vec2::zero() -> Vec2 {
  { x: 0.0, y: 0.0 }
}

///|
/// 向量加法
pub impl Add for Vec2 with fn add(self : Vec2, other : Vec2) -> Vec2 {
  { x: self.x + other.x, y: self.y + other.y }
}

///|
/// 向量减法
pub impl Sub for Vec2 with fn sub(self : Vec2, other : Vec2) -> Vec2 {
  { x: self.x - other.x, y: self.y - other.y }
}

///|
/// 向量逐元素乘法 (Hadamard product)
pub impl Mul for Vec2 with fn mul(self : Vec2, other : Vec2) -> Vec2 {
  { x: self.x * other.x, y: self.y * other.y }
}

///|
/// 向量逐元素除法
pub impl Div for Vec2 with fn div(self : Vec2, other : Vec2) -> Vec2 {
  { x: self.x / other.x, y: self.y / other.y }
}

///|
/// 标量乘法
pub fn Vec2::scale(self : Vec2, s : Double) -> Vec2 {
  { x: self.x * s, y: self.y * s }
}

///|
/// 标量除法
pub fn Vec2::div_scalar(self : Vec2, s : Double) -> Vec2 {
  { x: self.x / s, y: self.y / s }
}

///|
/// 向量点积
pub fn Vec2::dot(self : Vec2, other : Vec2) -> Double {
  self.x * other.x + self.y * other.y
}

///|
/// 向量 L2 范数（长度）平方
pub fn Vec2::norm_sqr(self : Vec2) -> Double {
  self.dot(self)
}

///|
/// 向量 L2 范数（长度）
pub fn Vec2::norm(self : Vec2) -> Double {
  self.norm_sqr().sqrt()
}

///|
/// 两点之间的欧氏距离
pub fn Vec2::dist(self : Vec2, other : Vec2) -> Double {
  (self - other).norm()
}

///|
/// 向量归一化，如为零向量则返回零向量
pub fn Vec2::normalize(self : Vec2) -> Vec2 {
  let len = self.norm()
  if len == 0.0 {
    Vec2::zero()
  } else {
    self.div_scalar(len)
  }
}

///|
/// 线性插值 (Lerp): (1 - t) * self + t * other
pub fn Vec2::lerp(self : Vec2, other : Vec2, t : Double) -> Vec2 {
  self.scale(1.0 - t) + other.scale(t)
}

///|
/// 矩阵结构体，用于多维线性变换和投影
pub(all) struct Matrix {
  rows : Int
  cols : Int
  data : Array[Double]
} derive(Debug, Eq)

///|
/// 创建指定行、列的矩阵，默认初始化为 0.0
pub fn Matrix::new(rows : Int, cols : Int, init? : Double = 0.0) -> Matrix {
  { rows, cols, data: Array::make(rows * cols, init) }
}

///|
/// 获取矩阵元素 (r, c)
pub fn Matrix::get(self : Matrix, r : Int, c : Int) -> Double {
  self.data[r * self.cols + c]
}

///|
/// 设置矩阵元素 (r, c)
pub fn Matrix::set(self : Matrix, r : Int, c : Int, val : Double) -> Unit {
  self.data[r * self.cols + c] = val
}

///|
/// 矩阵与 2D 向量乘法 (假设矩阵为 2x2)
pub fn Matrix::matvec2(self : Matrix, vec : Vec2) -> Vec2 {
  let x = self.get(0, 0) * vec.x + self.get(0, 1) * vec.y
  let y = self.get(1, 0) * vec.x + self.get(1, 1) * vec.y
  { x, y }
}
