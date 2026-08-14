///|
test "bootstrap interval is reproducible and bounded" {
  let interval = bootstrap_mean([1.0, 2.0, 3.0, 4.0], 20, 42)
  inspect(interval.estimate, content="2.5")
  inspect(interval.lower <= interval.estimate, content="true")
  inspect(interval.upper >= interval.estimate, content="true")
  inspect(interval.resamples, content="20")
  inspect(interval_markdown("demo", interval).contains("demo"), content="true")
}
