///|
test "calibration derives a deterministic quality gate" {
  let reports = [
    @benchmark.run_benchmark(
      @benchmark.BenchmarkConfig::quick(
        @benchmark.TwoMoons,
        @benchmark.DDPM,
        2026UL,
      ),
    ),
    @benchmark.run_benchmark(
      @benchmark.BenchmarkConfig::quick(
        @benchmark.TwoMoons,
        @benchmark.DDIM,
        2027UL,
      ),
    ),
  ]
  let result = calibrate(reports, 0.5)
  inspect(result.sample_count, content="2")
  inspect(result.recommended_threshold >= result.mean, content="true")
  inspect(result.observed_pass_rate >= 0.5, content="true")
  inspect(accepts(result, result.mean), content="true")
}

///|
test "percentile handles empty and bounded inputs" {
  inspect(percentile([], 0.5), content="0")
  inspect(percentile([1.0, 3.0, 5.0], 0.5), content="3")
  inspect(percentile([1.0, 3.0, 5.0], -1.0), content="1")
  inspect(percentile([1.0, 3.0, 5.0], 2.0), content="5")
}
