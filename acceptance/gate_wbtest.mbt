///|
test "artifact validation checks real structural markers" {
  inspect(artifact_is_valid("html", ""), content="false")
  inspect(artifact_is_valid("svg", "<svg></svg>"), content="false")
  let svg = "<svg viewBox=\"0 0 10 10\"><circle cx=\"1\" cy=\"1\" /></svg>"
  inspect(artifact_is_valid("svg", svg), content="false")
}

///|
test "matrix and check helpers reject incomplete evidence" {
  inspect(matrix_is_complete([], 6, 3), content="false")
  inspect(checks_are_ready([]), content="false")
  let checks = [GateCheck::new("unit", true, "ok")]
  inspect(checks_are_ready(checks), content="true")
  inspect(failed_check_names(checks), content="none")
}

///|
test "report exporters expose release status" {
  let report : AcceptanceReport = {
    seed: 2026UL,
    checks: [GateCheck::new("unit", true, "ok")],
    benchmark_case_count: 18,
    experiment_case_count: 18,
    benchmark_pass_rate: 1.0,
    experiment_pass_rate: 1.0,
    quality_score: 0.8,
    html_bytes: 256,
    svg_bytes: 128,
    ready: true,
  }
  inspect(report_markdown(report).contains("PASS"), content="true")
  inspect(report_json(report).contains("\"ready\":true"), content="true")
  inspect(report_json(report).contains("\"checks\""), content="true")
}
