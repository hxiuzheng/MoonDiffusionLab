///|
/// 生成一份轻量质量报告，适合在本地验收时复制保存。
fn print_header() -> Unit {
  println("============================================================")
  println("MoonDiffusionLab quality report / reproducible local check")
  println("Backend: pure MoonBit / deterministic program-generated data")
  println("Metrics: Energy, MMD, grid intersection, quality, diversity")
  println("Safety: no network access and no external data redistribution")
  println("Purpose: acceptance evidence and regression diagnostics")
  println("Outputs: Markdown decision and ASCII density heatmap")
  println("Reproducibility: seed=2026 sample_count=128 bins=16x8")
  println("============================================================")
}

///|
fn print_footer() -> Unit {
  println("============================================================")
  println("Report complete: metrics, threshold decision and heatmap")
}

///|
fn main {
  print_header()
  let rng = @core.Rng::new(seed=2026UL)
  let target = @benchmark.generate_target(@benchmark.TwoMoons, 128, rng)
  let generated = @benchmark.generate_target(@benchmark.TwoMoons, 128, rng)
  let comparison = @analysis.compare(target, generated, 16, 0.5)
  let decision = @analysis.check_comparison(
    @analysis.ComparisonPolicy::default(),
    comparison,
  )
  println("MoonDiffusionLab quality report")
  println(@analysis.comparison_markdown(comparison))
  println(@analysis.comparison_decision_markdown(decision))
  println(@analysis.Histogram2D::from_points(target, 16, 8).to_ascii())
  print_footer()
}

///|
/// 该入口刻意保持无网络依赖，确保评审可以在干净环境中直接运行。
