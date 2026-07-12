# MoonDiffusionLab 扩散模型原理实验工具箱

[![MoonBit](https://img.shields.io/badge/Language-MoonBit-00ffcc?style=flat-square)](https://www.moonbitlang.com/)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache--2.0-blue.svg?style=flat-square)](https://opensource.org/licenses/Apache-2.0)
[![OSC 2026](https://img.shields.io/badge/Competition-OSC%202026-ff3366?style=flat-square)](https://moonbitlang.github.io/OSC2026/)
[![CI](https://img.shields.io/badge/CI-GitHub%20Actions-111827?style=flat-square)](./.github/workflows/test.yml)

MoonDiffusionLab 是一个纯 MoonBit 实现的 1D/2D Toy Diffusion 教学与实验工具箱，面向生成模型原理演示、采样过程观察和可视化对比。

## 项目特点

- 纯 MoonBit 原生实现，覆盖 `core`、`schedule`、`dataset`、`model`、`diffusion`、`visualize`、`cmd/lab` 七个模块
- 支持 Linear、Cosine、Sigmoid 噪声调度
- 支持 Two Moons、Swiss Roll、GMM Ring、Bimodal 等 toy 数据集
- 提供 Analytical Score Field 与 Toy MLP 两种评分模型
- 集成 DDPM、DDIM、Euler ODE 三类采样方式
- 支持终端 ASCII、SVG 和 HTML 报告输出

## 快速开始

运行主程序：

```bash
moon run cmd/lab
```

运行测试：

```bash
moon test
```

运行检查与接口生成：

```bash
moon check
moon info
```

## CI

仓库已补充 GitHub Actions 工作流，推送或提交流时会自动执行：

```bash
moon check --target all
moon fmt --deny-warn
moon info --deny-warn
moon test --target all
```

其中 `moontest` 对应的就是 MoonBit 的 `moon test` 阶段。

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

- 已通过本地 `moon check`
- 已通过本地 `moon test`（19/19）
- 已补齐 GitHub Actions CI
- 已提供 Apache-2.0 许可证

## 相关文档

- [OSC2026 合规验证报告](docs/OSC2026_COMPLIANCE.md)
- [OSC2026 自查报告](OSC2026_SELF_REVIEW.md)
- [项目申报书](MoonDiffusionLab_申报书.md)

## 许可证

Apache-2.0
