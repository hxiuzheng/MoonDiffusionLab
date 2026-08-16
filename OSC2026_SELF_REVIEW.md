# MoonDiffusionLab：OSC 2026 最终验收自查

检查日期：2026-08-16

## 结论

本地源码与工程结构已达到可复核状态：项目是有效 MoonBit 模块，根目录有 Apache-2.0 许可证，README、申报书、架构说明和验收证据清单齐备。当前本地硬性检查已经通过：`moon check --target all --deny-warn`、`moon build`、`moon test --deny-warn`、`moon fmt`、`moon info --target all` 和 `moon run cmd/acceptance_gate`。

本次代码更新完成后，需以同一提交重新推送 GitHub/GitLink，并以 `hxiuzheng` 命名空间发布 `mooncakes.io` 版本后执行 `moon add` 验证；三平台 CI 还必须包含 `cmd/acceptance_gate` 和全部 CLI smoke tests。

## 已核对证据

- 代码规模：61 个 `.mbt` 文件，4,689 行 MoonBit 源码。
- 测试：43 个测试全部通过，且 deny-warn 检查通过。
- 功能：`core`、`schedule`、`dataset`、`model`、`diffusion`、`visualize`、`benchmark`、`analysis`、`experiment`、`acceptance` 和六个命令行入口均已纳入模块。
- CI：`.github/workflows/test.yml` 覆盖 Ubuntu、macOS、Windows，并执行 check、build、fmt、info、test、全部 CLI smoke tests 和发布门禁。
- 文档：使用方法、功能边界、验收命令和发布前提见 README 与 `docs/ACCEPTANCE_CHECKLIST.md`。
- 合规：根目录 Apache-2.0；`moon.mod` 的 repository URL 与 GitHub 主仓一致；远端 URL 不包含账号密码或令牌。
- 产物：`assets/demo.html` 和 `assets/demo.svg` 均已纳入版本控制，可在离线环境直接查看。

## 外部发布核验

- 当前版本已推送到 GitHub 与 GitLink，两端 `master` 指向一致，远端 CI 三个平台均通过。
- 使用 `hxiuzheng` 对应的 mooncakes.io 身份执行 `moon publish`，并在干净临时目录执行 `moon add hxiuzheng/moon_diffusion_lab`。
- 已在临时 MoonBit 项目中用 `moon add` 验证已发布版本可下载并通过 `moon check`；本次源码更新后的 `0.1.5` 需要重新发布并复核。
- 在干净检出中重新执行 `docs/ACCEPTANCE_CHECKLIST.md` 的全部命令并保存结果。
