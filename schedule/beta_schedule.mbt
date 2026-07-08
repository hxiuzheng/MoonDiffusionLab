///|
/// 噪声调度器返回的预计算表结构，包含了从 t = 0 到 t = T - 1 的所有统计参数
pub(all) struct DiffusionSchedule {
  steps : Int
  betas : Array[Double]
  alphas : Array[Double]
  alphas_cumprod : Array[Double]
  sqrt_alphas_cumprod : Array[Double]
  sqrt_one_minus_alphas_cumprod : Array[Double]
  posterior_variance : Array[Double]
} derive(Debug, Eq)

///|
/// 调度策略枚举
pub(all) enum ScheduleType {
  Linear(beta_start~ : Double, beta_end~ : Double)
  Cosine(s~ : Double)
  Sigmoid(beta_start~ : Double, beta_end~ : Double)
} derive(Debug, Eq)

///|
/// 根据给定的调度策略与步数构建预计算参数表
pub fn DiffusionSchedule::create(
  steps : Int,
  schedule_type : ScheduleType,
) -> DiffusionSchedule {
  let betas = match schedule_type {
    Linear(beta_start~, beta_end~) =>
      make_linear_betas(steps, beta_start~, beta_end~)
    Cosine(s~) => make_cosine_betas(steps, s~)
    Sigmoid(beta_start~, beta_end~) =>
      make_sigmoid_betas(steps, beta_start~, beta_end~)
  }

  let alphas = Array::make(steps, 0.0)
  let alphas_cumprod = Array::make(steps, 0.0)
  let sqrt_alphas_cumprod = Array::make(steps, 0.0)
  let sqrt_one_minus_alphas_cumprod = Array::make(steps, 0.0)
  let posterior_variance = Array::make(steps, 0.0)

  let mut cumprod = 1.0
  for i in 0..<steps {
    let alpha = 1.0 - betas[i]
    alphas[i] = alpha
    cumprod = cumprod * alpha
    alphas_cumprod[i] = cumprod
    sqrt_alphas_cumprod[i] = cumprod.sqrt()
    sqrt_one_minus_alphas_cumprod[i] = (1.0 - cumprod).sqrt()

    if i == 0 {
      posterior_variance[i] = 0.0
    } else {
      let alpha_cumprod_prev = alphas_cumprod[i - 1]
      posterior_variance[i] = betas[i] *
        (1.0 - alpha_cumprod_prev) /
        (1.0 - cumprod)
    }
  }

  {
    steps,
    betas,
    alphas,
    alphas_cumprod,
    sqrt_alphas_cumprod,
    sqrt_one_minus_alphas_cumprod,
    posterior_variance,
  }
}

///|
/// 获取指定步长 t 的 alpha_t
pub fn DiffusionSchedule::get_alpha(
  self : DiffusionSchedule,
  t : Int,
) -> Double {
  self.alphas[t]
}

///|
/// 获取指定步长 t 的累乘 alpha_bar_t
pub fn DiffusionSchedule::get_alpha_bar(
  self : DiffusionSchedule,
  t : Int,
) -> Double {
  self.alphas_cumprod[t]
}

///|
/// 获取指定步长 t 的前向信号缩放系数 sqrt(alpha_bar_t)
pub fn DiffusionSchedule::get_sqrt_alpha_bar(
  self : DiffusionSchedule,
  t : Int,
) -> Double {
  self.sqrt_alphas_cumprod[t]
}

///|
/// 获取指定步长 t 的前向噪声缩放系数 sqrt(1 - alpha_bar_t)
pub fn DiffusionSchedule::get_sqrt_one_minus_alpha_bar(
  self : DiffusionSchedule,
  t : Int,
) -> Double {
  self.sqrt_one_minus_alphas_cumprod[t]
}
