# MoonDiffusionLab 扩散模型原理实验工具箱

[![MoonBit](https://img.shields.io/badge/Language-MoonBit-00ffcc?style=flat-square)](https://www.moonbitlang.com/)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache--2.0-blue.svg?style=flat-square)](https://opensource.org/licenses/Apache-2.0)
[![OSC 2026](https://img.shields.io/badge/Competition-OSC%202026-ff3366?style=flat-square)](https://moonbitlang.github.io/OSC2026/)
[![CI](https://img.shields.io/badge/CI-GitHub%20Actions-111827?style=flat-square)](./.github/workflows/check.yml)

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
**可视化产物（SVG/HTML）真实落盘复现**：
本项目支持将采样流场和多帧交互报告保存为静态文件。您可以直接运行脚本生成（或使用 `>` 重定向输出）：
```bash
# 生成交互式网页报告
moon run cmd/export_html > assets/demo.html
# 生成流场矢量图
moon run cmd/export_svg > assets/demo.svg
```

### 4. 测试与构建
```bash
moon check
moon build
moon test
```

## 项目特点

- 纯 MoonBit 原生实现，无外部依赖。
- 支持 Linear、Cosine、Sigmoid 噪声调度。
- 涵盖 Two Moons、Swiss Roll、GMM Ring、Bimodal 等 toy 数据集。
- 提供 Analytical Score Field 与 Toy MLP 两种预测模型。
- 集成 DDPM、DDIM、Euler ODE 采样器及 JSON、Markdown 导出。
- 支持终端 ASCII、SVG 流场和交互式 HTML 报告多模态呈现。

## CI

仓库已补充 GitHub Actions 自动化工作流，每次推送时会自动执行以下步骤（不再使用旧版不支持的参数）：
```bash
moon check
moon build
moon test
```

## 代码示例

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

- 已通过最新版 `moon check`, `moon build`, `moon test` (19/19)。
- 已完善 `ToyMLP` 的 DDPM 采样闭环。
- 已补齐 GitHub Actions CI 流水线。
- 已发布至 [mooncakes.io](https://mooncakes.io/)。
- 提供真正的落盘示例 (`assets/demo.svg` 与 `assets/demo.html`)。

## 许可证

Apache-2.0
