# MoonDiffusionLab：OSC 2026 最终验收自查

检查日期：2026-08-16

## 结论

本地源码与工程结构已达到可复核状态：项目是有效 MoonBit 模块，根目录有 Apache-2.0 许可证，README、申报书、架构说明和验收证据清单齐备。当前本地硬性检查已经通过：`moon check --target all --deny-warn`、`moon build`、`moon test --deny-warn`、`moon fmt`、`moon info --target all` 和 `moon run cmd/acceptance_gate`。

功能提交 `50f0a3734f9bd8a3b2311f538759d17b3a4f2e95` 及最终文档提交已推送到正确的 GitHub/GitLink 仓库；GitHub Actions 运行 `31954424015` 的 Ubuntu、macOS、Windows 三平台和全部 CLI smoke tests 均通过。

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
- `hxiuzheng` 对应的 mooncakes.io 身份已成功发布 `hxiuzheng/moon_diffusion_lab@0.1.6`；独立消费者已锁定该版本并通过 `moon check --target all --deny-warn`，实际调用库 API 也通过。
- 本地全量检查、发布包内检查、独立消费者检查和远端三平台 CI 均已完成；`docs/ACCEPTANCE_CHECKLIST.md` 中的验收工作链已具备可重复证据。
