///|
test "sampler summaries preserve matrix coverage" {
  let cases = default_plan(2026UL, 1)
  let results = run_plan(cases)
  let summary = summarize_sampler(results, @benchmark.DDIM)
  inspect(summary.cases, content="6")
  inspect(summary.stable_cases >= 0, content="true")
  inspect(
    sampler_summary_markdown(results).contains("Mean coverage"),
    content="true",
  )
}
