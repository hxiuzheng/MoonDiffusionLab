///|
test "benchmark configuration rejects unsafe ranges" {
  let config = BenchmarkConfig::quick(TwoMoons, DDIM, 2026UL)
  inspect(config.is_valid(), content="true")
  inspect(config.validation_message(), content="ok")

  let invalid : BenchmarkConfig = {
    dataset: TwoMoons,
    sampler: DDIM,
    target_count: 1,
    sample_count: 0,
    diffusion_steps: 2,
    sampling_steps: 4,
    seed: 1UL,
  }
  inspect(invalid.is_valid(), content="false")
  inspect(
    invalid.validation_message(),
    content="target_count must be greater than 1",
  )
}

///|
test "benchmark metrics detect identical distributions" {
  let points = [
    @core.Vec2::new(-1.0, 0.0),
    @core.Vec2::new(0.0, 1.0),
    @core.Vec2::new(1.0, 0.0),
  ]
  let metrics = evaluate_metrics(points, points)
  inspect(metrics.wasserstein, content="0")
  inspect(metrics.mean_error, content="0")
  inspect(metrics.variance_error, content="0")
  inspect(metrics.coverage, content="1")
  inspect(metrics.out_of_bounds, content="0")
}

///|
test "target generators cover every supported benchmark" {
  let rng = @core.Rng::new(seed=123UL)
  let datasets = [Uniform1D, Gaussian1D, TwoMoons, SwissRoll, GmmRing, Bimodal]
  for dataset in datasets {
    let points = generate_target(dataset, 16, rng)
    inspect(points.length(), content="16")
  }
}

///|
test "reports are exportable and deterministic" {
  let config = BenchmarkConfig::quick(Gaussian1D, DDIM, 99UL)
  let first = run_benchmark(config)
  let second = run_benchmark(config)
  inspect(report_json(first) == report_json(second), content="true")
  inspect(report_csv_row(first).contains("gaussian_1d"), content="true")
  inspect(suite_csv([first]).contains("dataset,sampler"), content="true")
  inspect(suite_markdown([first]).contains("| Dataset |"), content="true")
}

///|
test "suite helpers handle empty and non-empty reports" {
  inspect(suite_pass_rate([]), content="0")
  inspect(suite_is_healthy([], minimum_rate=0.5), content="false")
  let report = run_benchmark(BenchmarkConfig::quick(Uniform1D, DDIM, 7UL))
  let reports = [report]
  inspect(suite_pass_rate(reports) >= 0.0, content="true")
  inspect(suite_csv(reports).split("\n").length() > 1, content="true")
}
