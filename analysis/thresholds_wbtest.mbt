///|
test "comparison policy passes identical distributions" {
  let points = [
    @core.Vec2::new(-1.0, 0.0),
    @core.Vec2::new(0.0, 1.0),
    @core.Vec2::new(1.0, 0.0),
  ]
  let comparison = compare(points, points, 4, 0.5)
  let decision = check_comparison(ComparisonPolicy::default(), comparison)
  inspect(decision.passed, content="true")
  inspect(decision.failed_checks, content="0")
  inspect(
    comparison_pass_rate(ComparisonPolicy::default(), [comparison]),
    content="1",
  )
}

///|
test "comparison policy catches a separated distribution" {
  let target = [@core.Vec2::new(0.0, 0.0), @core.Vec2::new(0.1, 0.1)]
  let generated = [@core.Vec2::new(10.0, 10.0), @core.Vec2::new(10.1, 10.1)]
  let comparison = compare(target, generated, 4, 0.5)
  let decision = check_comparison(ComparisonPolicy::default(), comparison)
  inspect(decision.passed, content="false")
  inspect(decision.failed_checks > 0, content="true")
  inspect(
    comparison_decision_markdown(decision).contains("FAIL"),
    content="true",
  )
}
