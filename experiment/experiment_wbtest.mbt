///|
test "default plan covers the comparison matrix" {
  let cases = default_plan(2026UL, 2)
  inspect(cases.length(), content="18")
  inspect(cases[0].repeats, content="2")
  inspect(cases[0].name, content="uniform_1d/ddpm")
  inspect(cases[17].name, content="bimodal/euler")
}

///|
test "repeated case aggregation is deterministic" {
  let config = @benchmark.BenchmarkConfig::quick(
    @benchmark.Gaussian1D,
    @benchmark.DDIM,
    88UL,
  )
  let case = ExperimentCase::new("gaussian", config, 2)
  let first = run_case(case)
  let second = run_case(case)
  inspect(first.mean_wasserstein == second.mean_wasserstein, content="true")
  inspect(first.repeats, content="2")
  inspect(first.best_seed == 88UL || first.best_seed == 8007UL, content="true")
}

///|
test "report exporters expose ranking data" {
  let config = @benchmark.BenchmarkConfig::quick(
    @benchmark.Uniform1D,
    @benchmark.DDIM,
    7UL,
  )
  let result = run_case(ExperimentCase::new("uniform", config, 1))
  let results = [result]
  inspect(result_json(result).contains("mean_wasserstein"), content="true")
  inspect(results_csv(results).contains("best_seed"), content="true")
  inspect(results_markdown(results).contains("| Rank |"), content="true")
  inspect(average_pass_rate(results) >= 0.0, content="true")
  inspect(best_result(results) is Some(_), content="true")
  inspect(best_result([]) is None, content="true")
}
