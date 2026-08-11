///|
/// 可复现基准数据集集合。每个数据集都由程序生成，避免把外部数据的
/// 许可、下载和版本漂移带入最小实验环境。
pub(all) enum BenchmarkDataset {
  Uniform1D
  Gaussian1D
  TwoMoons
  SwissRoll
  GmmRing
  Bimodal
} derive(Debug, Eq)

///|
/// 参与基准的反向采样器。
pub(all) enum SamplerBackend {
  DDPM
  DDIM
  Euler
} derive(Debug, Eq)

///|
/// 一次基准运行的完整配置。
pub(all) struct BenchmarkConfig {
  dataset : BenchmarkDataset
  sampler : SamplerBackend
  target_count : Int
  sample_count : Int
  diffusion_steps : Int
  sampling_steps : Int
  seed : UInt64
} derive(Debug, Eq)

///|
/// 创建一份适合快速本地回归的配置。
pub fn BenchmarkConfig::quick(
  dataset : BenchmarkDataset,
  sampler : SamplerBackend,
  seed : UInt64,
) -> BenchmarkConfig {
  {
    dataset,
    sampler,
    target_count: 128,
    sample_count: 128,
    diffusion_steps: 30,
    sampling_steps: 8,
    seed,
  }
}

///|
/// 判断配置是否满足采样器和数据集的基本约束。
pub fn BenchmarkConfig::is_valid(self : BenchmarkConfig) -> Bool {
  self.target_count > 1 &&
  self.sample_count > 1 &&
  self.diffusion_steps >= 4 &&
  self.sampling_steps >= 1 &&
  self.sampling_steps <= self.diffusion_steps
}

///|
/// 返回面向 CLI 的配置错误说明。
pub fn BenchmarkConfig::validation_message(self : BenchmarkConfig) -> String {
  if self.target_count <= 1 {
    "target_count must be greater than 1"
  } else if self.sample_count <= 1 {
    "sample_count must be greater than 1"
  } else if self.diffusion_steps < 4 {
    "diffusion_steps must be at least 4"
  } else if self.sampling_steps < 1 {
    "sampling_steps must be positive"
  } else if self.sampling_steps > self.diffusion_steps {
    "sampling_steps cannot exceed diffusion_steps"
  } else {
    "ok"
  }
}

///|
/// 统一生成基准目标数据。每次调用只消耗传入的随机数发生器，
/// 因而调用方可以通过固定 seed 精确复现报告。
pub fn generate_target(
  dataset : BenchmarkDataset,
  count : Int,
  rng : @core.Rng,
) -> Array[@core.Vec2] {
  match dataset {
    Uniform1D => @dataset.sample_1d_uniform(count, rng)
    Gaussian1D => @dataset.sample_1d_gaussian(count, rng)
    TwoMoons => @dataset.sample_two_moons(count, noise=0.05, rng)
    SwissRoll => @dataset.sample_swiss_roll(count, noise=0.05, rng)
    GmmRing => @dataset.sample_gmm_ring(count, radius=2.0, noise=0.1, rng)
    Bimodal => @dataset.sample_bimodal(count, dist=2.0, noise=0.15, rng)
  }
}

///|
/// 为每种数据集选择稳定的噪声调度。
pub fn schedule_for(
  dataset : BenchmarkDataset,
  steps : Int,
) -> @schedule.DiffusionSchedule {
  match dataset {
    Uniform1D | Gaussian1D =>
      @schedule.DiffusionSchedule::create(
        steps,
        @schedule.Linear(beta_start=0.0005, beta_end=0.02),
      )
    TwoMoons | SwissRoll =>
      @schedule.DiffusionSchedule::create(steps, @schedule.Cosine(s=0.008))
    GmmRing | Bimodal =>
      @schedule.DiffusionSchedule::create(
        steps,
        @schedule.Sigmoid(beta_start=0.0005, beta_end=0.025),
      )
  }
}

///|
/// 评估结果中的数值指标。误差均为非负值，越小越好。
pub(all) struct BenchmarkMetrics {
  wasserstein : Double
  mean_error : Double
  variance_error : Double
  coverage : Double
  out_of_bounds : Int
} derive(Debug, Eq)

///|
/// 一个可直接用于 CI 阈值判断的基准报告。
pub(all) struct BenchmarkReport {
  dataset : BenchmarkDataset
  sampler : SamplerBackend
  seed : UInt64
  target_count : Int
  sample_count : Int
  metrics : BenchmarkMetrics
  passed : Bool
} derive(Debug, Eq)

///|
fn abs_diff(a : Double, b : Double) -> Double {
  (a - b).abs()
}

///|
fn mean_error(
  target : Array[@core.Vec2],
  generated : Array[@core.Vec2],
) -> Double {
  let a = @core.mean_vec2(target)
  let b = @core.mean_vec2(generated)
  (abs_diff(a.x, b.x) + abs_diff(a.y, b.y)) * 0.5
}

///|
fn variance_error(
  target : Array[@core.Vec2],
  generated : Array[@core.Vec2],
) -> Double {
  let a = @core.variance_vec2(target)
  let b = @core.variance_vec2(generated)
  (abs_diff(a.x, b.x) + abs_diff(a.y, b.y)) * 0.5
}

///|
fn bounds(points : Array[@core.Vec2]) -> (@core.Vec2, @core.Vec2) {
  if points.length() == 0 {
    return (@core.Vec2::zero(), @core.Vec2::zero())
  }
  let first = points[0]
  let mut min_x = first.x
  let mut max_x = first.x
  let mut min_y = first.y
  let mut max_y = first.y
  for p in points {
    if p.x < min_x {
      min_x = p.x
    }
    if p.x > max_x {
      max_x = p.x
    }
    if p.y < min_y {
      min_y = p.y
    }
    if p.y > max_y {
      max_y = p.y
    }
  }
  (@core.Vec2::new(min_x, min_y), @core.Vec2::new(max_x, max_y))
}

///|
fn out_of_bounds_count(
  target : Array[@core.Vec2],
  generated : Array[@core.Vec2],
  margin : Double,
) -> Int {
  let (lo, hi) = bounds(target)
  let mut count = 0
  for p in generated {
    if p.x < lo.x - margin ||
      p.x > hi.x + margin ||
      p.y < lo.y - margin ||
      p.y > hi.y + margin {
      count += 1
    }
  }
  count
}

///|
fn coverage_ratio(
  target : Array[@core.Vec2],
  generated : Array[@core.Vec2],
  margin : Double,
) -> Double {
  if generated.length() == 0 {
    return 0.0
  }
  let outside = out_of_bounds_count(target, generated, margin)
  (generated.length() - outside).to_double() / generated.length().to_double()
}

///|
/// 计算两组点的统计质量，供不同采样器共享同一评价口径。
pub fn evaluate_metrics(
  target : Array[@core.Vec2],
  generated : Array[@core.Vec2],
) -> BenchmarkMetrics {
  let w = @core.sliced_wasserstein_approx(target, generated)
  let m = mean_error(target, generated)
  let v = variance_error(target, generated)
  let outside = out_of_bounds_count(target, generated, 1.0)
  {
    wasserstein: w,
    mean_error: m,
    variance_error: v,
    coverage: coverage_ratio(target, generated, 1.0),
    out_of_bounds: outside,
  }
}

///|
fn pass_threshold(metrics : BenchmarkMetrics) -> Bool {
  metrics.wasserstein < 2.5 &&
  metrics.mean_error < 1.0 &&
  metrics.variance_error < 3.0 &&
  metrics.coverage > 0.35
}

///|
fn sample_with_backend(
  config : BenchmarkConfig,
  target : Array[@core.Vec2],
  rng : @core.Rng,
) -> Array[@core.Vec2] {
  let model = @model.AnalyticalModel::new(target, bandwidth=0.1)
  let sched = schedule_for(config.dataset, config.diffusion_steps)
  match config.sampler {
    DDPM => {
      let (samples, _) = @diffusion.sample_ddpm_analytical(
        config.sample_count,
        model,
        sched,
        rng,
        record_interval=10,
      )
      samples
    }
    DDIM => {
      let (samples, _) = @diffusion.sample_ddim_analytical(
        config.sample_count,
        model,
        sched,
        rng,
        num_steps=config.sampling_steps,
      )
      samples
    }
    Euler => {
      let (samples, _) = @diffusion.sample_euler_analytical(
        config.sample_count,
        model,
        sched,
        rng,
        num_steps=config.sampling_steps,
      )
      samples
    }
  }
}

///|
/// 执行一次端到端基准：生成目标、采样、评估并返回报告。
/// 无效配置仍返回一个结构化报告，方便命令行程序打印错误而不崩溃。
pub fn run_benchmark(config : BenchmarkConfig) -> BenchmarkReport {
  let rng = @core.Rng::new(seed=config.seed)
  let target = generate_target(config.dataset, config.target_count, rng)
  if !config.is_valid() {
    let empty : Array[@core.Vec2] = []
    let metrics = evaluate_metrics(target, empty)
    return {
      dataset: config.dataset,
      sampler: config.sampler,
      seed: config.seed,
      target_count: config.target_count,
      sample_count: 0,
      metrics,
      passed: false,
    }
  }
  let generated = sample_with_backend(config, target, rng)
  let metrics = evaluate_metrics(target, generated)
  {
    dataset: config.dataset,
    sampler: config.sampler,
    seed: config.seed,
    target_count: target.length(),
    sample_count: generated.length(),
    metrics,
    passed: pass_threshold(metrics),
  }
}

///|
/// 对所有数据集运行同一种采样器，形成批量回归报告。
pub fn run_suite(
  sampler : SamplerBackend,
  seed : UInt64,
) -> Array[BenchmarkReport] {
  let datasets = [Uniform1D, Gaussian1D, TwoMoons, SwissRoll, GmmRing, Bimodal]
  let reports = Array::make(
    datasets.length(),
    run_benchmark(BenchmarkConfig::quick(datasets[0], sampler, seed)),
  )
  for i in 0..<datasets.length() {
    reports[i] = run_benchmark(
      BenchmarkConfig::quick(datasets[i], sampler, seed + i.to_uint64()),
    )
  }
  reports
}
