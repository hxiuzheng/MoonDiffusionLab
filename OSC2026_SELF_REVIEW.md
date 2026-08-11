# MoonDiffusionLab：OSC 2026 最终验收自查

检查日期：2026-08-11

## 结论

本地源码与工程结构已达到可复核状态：项目是有效 MoonBit 模块，根目录有 Apache-2.0 许可证，README、申报书、架构说明和验收证据清单齐备。当前本地硬性检查已经通过：`moon check --deny-warn`、`moon test --deny-warn`、`moon fmt --check`、`moon info --target all`。

仍不能宣称“已全部通过正式验收”，因为两个外部条件尚未在本地证实：

1. 最新提交尚未推送到 GitHub/GitLink 默认分支并获得通过的远端 CI 运行记录。
2. `moon publish --dry-run` 的本地打包通过，但注册中心拒绝了当前认证用户 `qyt1234567` 发布 `hxiuzheng/moon_diffusion_lab`；必须用与模块命名空间一致的账号完成登录后再正式发布。

## 已核对证据

- 代码规模：34 个 `.mbt` 文件，约 1,813 行有效 MoonBit 源码。
- 测试：19 个测试全部通过，且 deny-warn 检查通过。
- 功能：`core`、`schedule`、`dataset`、`model`、`diffusion`、`visualize` 和三个命令行入口均已纳入模块。
- CI：仅保留 `.github/workflows/test.yml`，覆盖 Ubuntu、macOS、Windows，并执行当前 CLI 支持的严格命令。
- 文档：使用方法、功能边界、验收命令和发布前提见 README 与 `docs/ACCEPTANCE_CHECKLIST.md`。
- 合规：根目录 Apache-2.0；远端 URL 已要求不得包含账号密码或令牌。

## 发布前必须完成

- 清理并轮换曾经写入本地 Git 配置的 GitLink 密码凭据，使用凭据管理器或 SSH。
- 使用 `hxiuzheng` 对应的 mooncakes.io 身份执行 `moon publish`。
- 推送最新提交到参赛仓库默认分支，确认远端 CI 三个平台均为通过。
- 在干净检出中重新执行 `docs/ACCEPTANCE_CHECKLIST.md` 的全部命令并保存结果。
