///|
/// 发布前验收 CLI：运行完整基准矩阵、质量判定和产物结构检查。
fn main {
  let report = @acceptance.run_release_gate(2026UL)
  println(@acceptance.report_markdown(report))
  println("Machine-readable status:")
  println(@acceptance.report_json(report))
  println(if report.ready { "RELEASE_GATE=PASS" } else { "RELEASE_GATE=FAIL" })
  if !report.ready {
    panic()
  }
}
