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
moon run cmd/experiment_runner
moon run cmd/quality_report
moon run cmd/acceptance_gate
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
- `acceptance`：六类数据集 × 三种采样器的基准矩阵、18 项实验计划、质量阈值、产物结构和可复现性门禁。

`moon run cmd/acceptance_gate` 是发布前完整工作链：它必须输出 `RELEASE_GATE=PASS`，并同时验证
真实采样结果、质量指标、HTML/SVG 内容标记、Markdown/JSON/CSV 导出和固定 seed 的字节级报告一致性。

项目是可解释的 1D/2D 教学与实验工具，不宣称替代生产级深度学习训练框架，也不包含模型权重、在线服务或未经授权的数据集。

## 开源合规

- 根目录 `LICENSE` 为 Apache-2.0。
- 当前实现与测试数据均为仓库内自有 MoonBit 源码和程序生成数据；没有复制第三方源码或随仓库分发外部数据集。
- Git 远端不得在 URL 中保存账号密码或访问令牌；应使用 SSH、凭据管理器或临时登录状态。

## 发布状态

当前模块版本为 `hxiuzheng/moon_diffusion_lab@0.1.5`；正式发布后应在干净临时目录执行
`moon add hxiuzheng/moon_diffusion_lab`，并把成功结果与远端 CI 运行记录一并作为验收证据。
