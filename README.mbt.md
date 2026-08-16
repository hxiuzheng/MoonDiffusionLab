# MoonDiffusionLab 扩散模型原理实验工具箱

[![MoonBit](https://img.shields.io/badge/Language-MoonBit-00ffcc?style=flat-square)](https://www.moonbitlang.com/)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache--2.0-blue.svg?style=flat-square)](https://opensource.org/licenses/Apache-2.0)
[![OSC 2026](https://img.shields.io/badge/Competition-OSC%202026-ff3366?style=flat-square)](https://moonbitlang.github.io/OSC2026/)
[![CI](https://img.shields.io/badge/CI-GitHub%20Actions-111827?style=flat-square)](./.github/workflows/test.yml)

MoonDiffusionLab 是一个基于 **MoonBit v0.10.3** 纯原生实现的 1D/2D Toy Diffusion 教学与实验工具箱，面向生成模型原理演示、采样过程观察和多模态可视化对比。

## 快速开始

### 1. 环境准备与克隆
确保您已安装最新版 MoonBit 工具链（推荐 `v0.10.3` 或以上）。
```bash
git clone https://github.com/hxiuzheng/MoonDiffusionLab.git
cd MoonDiffusionLab
moon install
```

### 2. 作为依赖包引入 (mooncakes.io)
您可以直接在您的项目中通过 `moon add` 引入本库：
```bash
moon add hxiuzheng/moon_diffusion_lab
```

### 3. 本地运行与产物复现
运行内置的实验主程序直接在控制台观看 ASCII 扩散动画：
```bash
moon run cmd/lab
```
重复实验与质量报告也可以直接运行：
```bash
moon run cmd/experiment_runner
moon run cmd/quality_report
moon run cmd/acceptance_gate
```
**可视化产物（SVG/HTML）真实落盘复现**：
本项目支持将采样流场和多帧交互报告保存为静态文件。您可以直接运行脚本生成（或使用 `>` 重定向输出）：
```bash
# 生成交互式网页报告
moon run cmd/export_html > assets/demo.html
# 生成流场矢量图
moon run cmd/export_svg > assets/demo.svg
```
仓库同时保留可直接查看的 `assets/demo.html` 与 `assets/demo.svg` 示例，便于离线验收和复现实验产物。

发布前完整工作链由 `cmd/acceptance_gate` 固化：它会运行六类程序生成数据集与三种采样器的
18 项基准、18 项重复实验、Two Moons 多指标质量阈值、HTML/SVG 结构检查，以及 Markdown/JSON/CSV
导出检查。固定 seed 下的报告可直接作为本地或 CI 验收证据。

### 4. 测试与构建
```bash
moon check --target all --deny-warn
moon build
moon fmt
moon info --target all
moon test --deny-warn
moon run cmd/acceptance_gate
```

## 项目特点

- 纯 MoonBit 原生实现，无外部依赖。
- 支持 Linear、Cosine、Sigmoid 噪声调度。
- 涵盖 Two Moons、Swiss Roll、GMM Ring、Bimodal 等 toy 数据集。
- 提供 Analytical Score Field 与 Toy MLP 两种预测模型。
- 集成 DDPM、DDIM、Euler ODE 采样器及 JSON、Markdown 导出。
- 支持终端 ASCII、SVG 流场和交互式 HTML 报告多模态呈现。

## 可复现实验基准

`benchmark` 包提供面向实际实验流程的统一评估入口：支持 Uniform、Gaussian、Two Moons、Swiss Roll、GMM Ring 和 Bimodal 六类数据集，覆盖 DDPM、DDIM、Euler 三种采样后端，并计算 Wasserstein 距离、均值误差、方差误差、覆盖率和越界点数。批量结果可导出为 JSON、CSV 或 Markdown，适合接入 CI、Notebook 和实验报告：

```mbt nocheck
let reports = @benchmark.run_suite(@benchmark.DDIM, 2026UL)
println(@benchmark.suite_markdown(reports))
println(@benchmark.suite_csv(reports))
```

该基准使用固定 seed 和程序生成数据，确保在无网络环境下也能复现；它用于回归比较和教学实验，不冒充外部真实数据集的统计结论。

## CI

仓库已补充 GitHub Actions 自动化工作流，每次推送时会自动执行以下步骤（不再使用旧版不支持的参数）：
```bash
moon check --target all --deny-warn
moon build
moon fmt
moon info --target all
moon test --deny-warn
moon run cmd/acceptance_gate

```

## 代码示例

同一工作流在 Ubuntu、macOS、Windows 三个平台执行 CLI smoke tests，并生成临时 HTML/SVG
产物验证完整工作链。

```mbt nocheck
import {
  "hxiuzheng/moon_diffusion_lab/core",
  "hxiuzheng/moon_diffusion_lab/schedule",
  "hxiuzheng/moon_diffusion_lab/model",
  "hxiuzheng/moon_diffusion_lab/dataset",
  "hxiuzheng/moon_diffusion_lab/diffusion",
  "hxiuzheng/moon_diffusion_lab/visualize",
}

fn main {
  let rng = @core.Rng::new(seed=2026UL)
  let data = @dataset.sample_two_moons(100, noise=0.05, rng)
  let sched = @schedule.DiffusionSchedule::create(30, Cosine(s=0.008))
  let model = @model.AnalyticalModel::new(data, bandwidth=0.1)
  let (samples, _) = @diffusion.sample_ddim_analytical(100, model, sched, rng, num_steps=5)

  println(@visualize.render_ascii_scatter(samples, title="DDIM 5-Step Denoised"))
  println(@core.sliced_wasserstein_approx(samples, data).to_string())
}
```

## 结项状态

- 当前仓库包含 61 个 MoonBit 文件、4,689 行源码，43/43 测试通过。
- 已完善 `ToyMLP` 的 DDPM 采样闭环。
- 已补齐 GitHub Actions CI 流水线。
- 发布验收门禁已通过，当前模块版本为 `hxiuzheng/moon_diffusion_lab@0.1.6`。
- 提供可由命令生成并落盘的 SVG/HTML 实验产物（默认输出目录为 `assets/`）。

## 许可证

Apache-2.0

## 验收与发布说明

项目的可复现验收命令、功能边界、测试证据和开源合规说明见 [`docs/ACCEPTANCE_CHECKLIST.md`](docs/ACCEPTANCE_CHECKLIST.md)。CI 使用当前 MoonBit CLI 支持的严格命令：`moon check --target all --deny-warn`、`moon fmt`、`moon info --target all` 和 `moon test --deny-warn`。

正式发布前请确认已使用与 `moon.mod` 中 `hxiuzheng/moon_diffusion_lab` 命名空间一致的 mooncakes.io 账号登录；项目不会把账号密码或访问令牌写入 Git remote URL。
