# MoonDiffusionLab：OSC 2026 最终验收自查

检查日期：2026-08-14

## 结论

本地源码与工程结构已达到可复核状态：项目是有效 MoonBit 模块，根目录有 Apache-2.0 许可证，README、申报书、架构说明和验收证据清单齐备。当前本地硬性检查已经通过：`moon check --target all --deny-warn`、`moon build`、`moon test --deny-warn`、`moon fmt`、`moon info --target all`。

本版本已推送到 GitHub/GitLink 默认分支，GitHub Actions 运行 `31771166468` 的 Ubuntu、macOS、Windows 三平台全部通过；当前尚待完成的外部核验只有用 `hxiuzheng` 命名空间发布 `mooncakes.io` 版本后执行 `moon add` 验证。

## 已核对证据

- 代码规模：58 个 `.mbt` 文件，4,145 行 MoonBit 源码。
- 测试：40 个测试全部通过，且 deny-warn 检查通过。
- 功能：`core`、`schedule`、`dataset`、`model`、`diffusion`、`visualize` 和三个命令行入口均已纳入模块。
- CI：仅保留 `.github/workflows/test.yml`，覆盖 Ubuntu、macOS、Windows，并执行 check、build、fmt、info、test 严格命令。
- 文档：使用方法、功能边界、验收命令和发布前提见 README 与 `docs/ACCEPTANCE_CHECKLIST.md`。
- 合规：根目录 Apache-2.0；远端 URL 已要求不得包含账号密码或令牌。

## 外部发布核验

- 已推送提交 `0b826fc23e5f5f8c8069a931692b0c2c674d37e6`，GitHub 与 GitLink 两端 `master` 指向一致，远端 CI 三个平台均通过。
- 使用 `hxiuzheng` 对应的 mooncakes.io 身份执行 `moon publish`，并在干净临时目录执行 `moon add hxiuzheng/moon_diffusion_lab`。
- 已在临时 MoonBit 项目中用 `moon add` 验证已发布的 `hxiuzheng/moon_diffusion_lab@0.1.3` 可下载并通过 `moon check`；`0.1.4` 仍待正确身份发布。
- 在干净检出中重新执行 `docs/ACCEPTANCE_CHECKLIST.md` 的全部命令并保存结果。
