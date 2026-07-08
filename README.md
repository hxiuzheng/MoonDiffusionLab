# MoonDiffusionLab 扩散模型原理实验工具箱

[![MoonBit](https://img.shields.io/badge/Language-MoonBit-00ffcc?style=flat-square)](https://www.moonbitlang.com/)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache--2.0-blue.svg?style=flat-square)](https://opensource.org/licenses/Apache-2.0)
[![OSC 2026](https://img.shields.io/badge/Competition-OSC%202026-ff3366?style=flat-square)](https://moonbitlang.github.io/OSC2026/)

**MoonDiffusionLab** 是专为生成模型教学与原理实验设计的 **1D/2D Toy Diffusion** 工具箱。本项目纯基于 [MoonBit](https://www.moonbitlang.com/) 原生开发，无需依赖任何外部 C/C++ 或 Python 深度学习库，用最轻量、直观、高可视化的方式彻底阐明扩散模型核心物理与统计机制。

---

##  项目核心亮点与特色

- **零依赖原生构建**：完全使用 MoonBit 编写，跨平台支持 `wasm-gc`、`native` 等多种后端，极速编译与运行。
- **覆盖核心原理全链路**：
  - **噪声调度器 (Noise Schedules)**：支持 DDPM 标准线性调度 (Linear)、Nichol 余弦平滑调度 (Cosine) 与 Sigmoid 调度。
  - **经典 2D 拓扑流形数据集**：内置双月分布 (Two Moons)、瑞士卷分布 (Swiss Roll)、8-高斯环形分布 (GMM Ring) 及双峰分布 (Bimodal)。
  - **双轨评分模型**：提供无需训练即可演示极限最优去噪效果的**分析式贝叶斯后验评分场 (Analytical Score Field)**，以及可手工初始化的**轻量级原生多层感知机 (Toy MLP)**。
  - **多元去噪采样器**：集成随机去噪 DDPM 采样器、确定性加速 DDIM 采样器、以及常微分方程连续时间流场 Euler ODE 采样器。
- **多模态强视觉表现力**：
  - **终端 ASCII 散点字符画**：在命令行界面即时呈现散点云图加噪与去噪演变。
  - **SVG 矢量图与评分流场**：高精度渲染扩散漂移向量箭尾流场图。
  - **交互式 HTML 教学实验报告**：一键生成多帧散点对比网页报告，开箱即用。

---

##  理论公式与物理推导

### 1. 前向加噪扩散过程 (Forward Noising Process)
扩散模型通过给定一系列方差表 $\beta_t \in (0, 1)$，逐步向原始数据 $x_0 \sim q(x)$ 中添加高斯噪声。设 $\alpha_t = 1 - \beta_t$ 以及 $\bar{\alpha}_t = \prod_{s=0}^t \alpha_s$，则任意步 $t$ 的后验分布可闭式解析表达为：
$$q(x_t | x_0) = \mathcal{N}\left(x_t; \sqrt{\bar{\alpha}_t} x_0, (1 - \bar{\alpha}_t) \mathbf{I}\right)$$

### 2. DDPM 逆向随机去噪采样 (Reverse Stochastic Sampling)
逆向过程通过估计加噪项 $\epsilon_\theta(x_t, t)$，利用马尔可夫链逐步还原数据：
$$x_{t-1} = \frac{1}{\sqrt{\alpha_t}} \left( x_t - \frac{\beta_t}{\sqrt{1 - \bar{\alpha}_t}} \epsilon_\theta(x_t, t) \right) + \sigma_t z, \quad z \sim \mathcal{N}(0, \mathbf{I})$$

### 3. DDIM 确定性采样与常微分方程流场 (Probability Flow ODE)
当随机项 $\sigma_t = 0$ 时，扩散过程等价于连续时间下的常微分方程 (ODE)，允许我们以 5~10 步的极少数步长快速生成高质量散点：
$$\frac{dx}{dt} = -\frac{1}{2} \beta(t) \left[ x - \nabla_x \log q_t(x) \right]$$

---

##  架构设计与包导览

项目严格遵循 MoonBit 模块化最佳实践，包含 7 大高内聚低耦合的子包：

| 包路径 | 模块名称 | 核心功能职责 |
| :--- | :--- | :--- |
| `core` | 底层计算包 | 提供 `Vec2` 向量与 `Matrix` 矩阵运算，XorShift64* 伪随机数与 Box-Muller 正态采样，以及 Sliced Wasserstein 距离估算 |
| `schedule` | 噪声调度包 | 预计算 $\alpha_t, \bar{\alpha}_t, \sigma_t^2$ 等物理统计参数，支持 Linear、Cosine、Sigmoid 策略 |
| `dataset` | Toy 数据集包 | 生成 2D 双月、瑞士卷、高斯环形以及 1D/2D 双峰测试散点云 |
| `model` | 预测模型包 | 实现了基于贝叶斯公式的分析式评分预测场 (Analytical Model) 与 MoonBit 原生 Toy MLP |
| `diffusion` | 扩散核心包 | 封装前向加噪 `q_sample`、多步去噪 `DDPM`、加速确定性 `DDIM` 与一阶积分 `Euler ODE` |
| `visualize` | 渲染引擎包 | 控制台 2D ASCII 字符画绘图、标准 SVG 散点/流场生成、以及 HTML 静态实验报告导出 |
| `cmd/lab` | 实验主程序 | 综合调用各包执行端到端四组核心对比实验，并终端输出所有演变过程与指标 |

---

##  快速上手指南

### 1. 运行实验演示主程序
在终端直接执行以下命令，即可在控制台观看丰富的 ASCII 散点演变图与实验指标评估：
```bash
moon run cmd/lab
```

### 2. 运行单元测试与包验证
全仓拥有高密度的黑盒/白盒单元测试覆盖，执行以下命令验证数值精确度与内存安全性：
```bash
moon test
```
执行类型检查与接口生成：
```bash
moon check
moon info
```

---

##  代码示例

以下代码展示了如何使用 `MoonDiffusionLab` 的 API 生成双月数据集，并利用分析式评分场进行 DDIM 5 步急速去噪：

```mbt nocheck
import {
  "username/moon_diffusion_lab/core",
  "username/moon_diffusion_lab/schedule",
  "username/moon_diffusion_lab/model",
  "username/moon_diffusion_lab/dataset",
  "username/moon_diffusion_lab/diffusion",
  "username/moon_diffusion_lab/visualize",
}

fn main {
  let rng = @core.Rng::new(seed=2026UL)
  
  // 1. 生成 100 个双月分布样本点
  let orig_data = @dataset.sample_two_moons(100, noise=0.05, rng)
  
  // 2. 创建余弦噪声调度器 (30 步)
  let sched = @schedule.DiffusionSchedule::create(30, Cosine(s=0.008))
  
  // 3. 构建分析式评分场模型
  let model = @model.AnalyticalModel::new(orig_data, bandwidth=0.1)
  
  // 4. 执行 DDIM 5 步确定性去噪采样
  let (samples, traj) = @diffusion.sample_ddim_analytical(100, model, sched, rng, num_steps=5)
  
  // 5. 打印 ASCII 结果并评估 Wasserstein 距离
  println(@visualize.render_ascii_scatter(samples, title="DDIM 5-Step Denoised"))
  let wass_dist = @core.sliced_wasserstein_approx(samples, orig_data)
  println("Sliced Wasserstein Distance: " + wass_dist.to_string())
}
```

---

##  大赛选题与开源合规说明

1. **选题方向**：生成模型教学与原理实验工具箱 (MoonDiffusionLab)。避开了竞争拥挤的通用 Web 框架或简单基础工具库，聚焦于前沿 AI 生成模型的数理底层机制与教学可视化。
2. **零依赖与纯手工制作**：本项目中所有向量计算、正态分布随机数采样、贝叶斯核密度估计、微积分 ODE 欧拉步进、以及 ASCII/SVG 渲染引擎均纯手工以 MoonBit 原生语法从零构建，不仅执行极快且无任何第三方版权或二进制依赖。
3. **开源协议**：本项目采用 Apache-2.0 开源许可证，欢迎社区进行二次开发、教学引用与算法扩展。

---
*Copyright © 2026 MoonDiffusionLab Contributors. All rights reserved.*
