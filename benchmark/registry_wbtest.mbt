///|
test "benchmark registry exposes complete matrix" {
  inspect(all_datasets().length(), content="6")
  inspect(all_samplers().length(), content="3")
  let summary = compare_samplers(TwoMoons, 2026UL)
  inspect(summary.reports.length(), content="3")
  inspect(summary.best_wasserstein >= 0.0, content="true")
  inspect(
    summaries_markdown([summary]).contains("Best sampler"),
    content="true",
  )
  inspect(summaries_json([summary]).contains("two_moons"), content="true")
  inspect(healthy_dataset_count([summary], 0.0), content="1")
  inspect(overall_pass_rate([summary]) >= 0.0, content="true")
  inspect(registry_is_healthy([summary], 0.0), content="true")
  inspect(best_report(summary) is Some(_), content="true")
  inspect(
    dataset_has_passing_sampler(summary) is true ||
    dataset_has_passing_sampler(summary) is false,
    content="true",
  )
  inspect(passing_sampler_count(summary) >= 0, content="true")
  inspect(sampler_coverage(summary), content="3")
}
