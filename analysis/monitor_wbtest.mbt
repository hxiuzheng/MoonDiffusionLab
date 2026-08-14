///|
test "monitor policy reports empty suite as failure" {
  let decision = check_reports(MonitorPolicy::default(), [])
  inspect(decision.status is Fail, content="true")
  inspect(decision.reason, content="no-reports")
}

///|
test "monitor can classify a reproducible benchmark" {
  let report = @benchmark.run_benchmark(
    @benchmark.BenchmarkConfig::quick(
      @benchmark.Gaussian1D,
      @benchmark.DDIM,
      2026UL,
    ),
  )
  let decision = check_report(MonitorPolicy::default(), report)
  inspect(decision.score >= 0.0, content="true")
  inspect(decision_markdown(decision).contains("Status"), content="true")
}
