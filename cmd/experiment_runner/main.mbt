///|
/// 运行一个轻量的端到端实验矩阵，作为用户可复制的命令行入口。
fn main {
  println("MoonDiffusionLab experiment matrix")
  println("seed=2026 repeats=1 datasets=6 samplers=3")
  let cases = @experiment.default_plan(2026UL, 1)
  let results = @experiment.run_plan(cases)
  println(@experiment.results_markdown(results))
  println(
    "Average pass rate: " + @experiment.average_pass_rate(results).to_string(),
  )
  match @experiment.best_result(results) {
    None => println("No result")
    Some(best) =>
      println("Best case: " + best.name + " seed=" + best.best_seed.to_string())
  }
}
