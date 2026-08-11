# OSC 2026 验收证据清单

这份清单用于最终验收前复核，记录可在干净检出中重复执行的证据，不把尚未完成的事项写成已完成。

## 当前硬性检查

在仓库根目录执行：

```bash
moon version --all
moon update
moon check --target all --deny-warn
moon build
moon fmt
moon info --target all
moon test --deny-warn
moon run cmd/lab
```

CI 对 Ubuntu、macOS、Windows 三个平台执行同一组检查，工作流位于 `.github/workflows/test.yml`。

## 功能边界与证据

- `core`：二维向量、张量、随机数、统计距离与边界检查。
- `schedule`：Linear、Cosine、Sigmoid 噪声调度及统计性质检查。
- `dataset`：Two Moons、Swiss Roll、GMM Ring、1D 分布与双峰分布。
- `model`：解析式 score field 与 Toy MLP 前向推理。
- `diffusion`：前向加噪、DDPM、DDIM、Euler ODE 与轨迹记录。
- `visualize`：ASCII、SVG、HTML、JSON、Markdown 导出。
- `cmd`：可复现实验、静态 SVG 和交互式 HTML 报告生成。

项目是可解释的 1D/2D 教学与实验工具，不宣称替代生产级深度学习训练框架，也不包含模型权重、在线服务或未经授权的数据集。

## 开源合规

- 根目录 `LICENSE` 为 Apache-2.0。
- 当前实现与测试数据均为仓库内自有 MoonBit 源码和程序生成数据；没有复制第三方源码或随仓库分发外部数据集。
- Git 远端不得在 URL 中保存账号密码或访问令牌；应使用 SSH、凭据管理器或临时登录状态。

## 发布状态

`moon publish --dry-run` 已通过本地打包、解包和再次检查。正式发布还需要使用与 `moon.mod` 模块命名空间 `hxiuzheng` 一致的 mooncakes.io 账号完成认证；认证用户不一致时，发布会被注册中心拒绝。
