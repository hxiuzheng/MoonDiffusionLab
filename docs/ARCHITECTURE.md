# MoonDiffusionLab 扩散模型技术架构与数学推导白皮书

## 1. 系统核心设计
`MoonDiffusionLab` 是完全基于 MoonBit 构建的轻量级 2D 扩散模型（Diffusion Model）仿真与训练可视化实验台。

## 2. 模块化与数学基础
- **张量与随机数数学引擎 (`core`)**：实现二维张量、Box-Muller 正态分布采样与 Sliced Wasserstein Distance 评估。
- **噪声调度器 (`schedule`)**：支持 Linear、Cosine 与 Sigmoid 调度公式，精确计算前向扩散累乘衰减参数 $\bar{\alpha}_t$。
- **模型与训练迭代 (`model` & `diffusion`)**：实现 DDPM 前向加噪与反向去噪迭代，结合损失计算进行拟合。
- **数据与可视化 (`dataset` & `visualize`)**：内置瑞士卷、双半月等经典分布，并提供 ASCII 与 SVG 图形渲染。
