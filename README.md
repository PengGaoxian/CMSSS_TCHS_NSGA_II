# CMSSS_TCHS_NSGA_II

云制造服务选择与调度优化代码，对应论文：

**Energy-QoS Collaborative Cloud Manufacturing Service Selection and Scheduling: A Task Cohesion Based Hybrid Scheduling NSGA-II (TCHS-NSGA-II)**

## 方法概述

本代码提出基于**任务衔接度（Task Cohesion）**的混合调度 NSGA-II 框架（TCHS-NSGA-II），在云制造环境下同时优化：

- **上层目标（Provider 侧）**：最小化制造设备的预热能耗
- **下层目标（Demander 侧）**：最大化综合 QoS（质量 Quality、成本 Cost、时间 Time 的加权组合）

### 任务衔接度

任务衔接度衡量子任务执行窗口与候选服务空闲时段的紧密程度：

- **前向衔接度**：服务开始时间距左侧空闲段起点的紧密程度
- **后向衔接度**：服务结束时间距右侧空闲段终点的紧密程度
- 实际预热能耗 = `Eh × (2 - cohesion)`，衔接度越高能耗越低

### 调度策略与算法

| 算法 | 主文件 | 调度函数 | 说明 |
|------|--------|----------|------|
| NSGA-II | `Main_FSGS.m` | `scheduling_Makespan.m` | 纯正向调度，以最早可用时间为准（MOS 策略） |
| MEOS-NSGA-II | `Main_MEOS.m` | `scheduling_Makespan_Energy.m` | TCHS-NSGA-II 的消融算法，仅使用 MEOS 调度策略（反向遍历） |
| EOS-NSGA-II | `Main_EOS.m` | `scheduling_Energy.m` | TCHS-NSGA-II 的消融算法，仅使用 EOS 调度策略（正向遍历） |
| ESGS-NSGA-II | `Main_ESGS_Forward.m` | `scheduling_Makespan_Energy_Forward.m` | 正向调度确定 makespan 后，**正向**遍历移动窗口以降低预热能耗 |
| **TCHS-NSGA-II** | `Main_TCHS.m` | — | **论文提出方法**：并行运行 MEOS 和 EOS 两种调度策略，合并两者帕累托前沿取外包络得到联合帕累托前沿 |
| MOEA/D | `Main_MOEAD.m` | `scheduling_Makespan.m` | Tchebycheff 分解框架，邻域协作进化（FSGS 调度策略） |
| MOPSO | `Main_MOPSO.m` | `scheduling_Makespan.m` | 多目标粒子群，外部存档维护帕累托前沿（FSGS 调度策略） |

> **TCHS 原理**：并行运行 MEOS（反向遍历）和 EOS（正向遍历）两种调度策略，将各自收敛后的帕累托前沿合并去重后重新计算联合帕累托前沿，
> 同时记录逐代 HV 历史用于收敛曲线对比。EOS-NSGA-II 与 MEOS-NSGA-II 为对应的消融算法。

## 运行方式

### 环境要求

MATLAB（无需额外工具箱）

### 快速开始

**步骤一：单次运行（默认规模 n=10, m=5）**

```matlab
% 在 MATLAB 中直接运行各算法主程序
Main_FSGS        % → outputs_n10_m5/Data_FSGS.mat
Main_MEOS        % → outputs_n10_m5/Data_MEOS.mat
Main_EOS         % → outputs_n10_m5/Data_EOS.mat
Main_ESGS_Forward % → outputs_n10_m5/Data_ESGS_Forward.mat
Main_MOEAD       % → outputs_n10_m5/Data_MOEAD.mat
Main_MOPSO       % → outputs_n10_m5/Data_MOPSO.mat
Main_TCHS        % → outputs_n10_m5/Data_TCHS.mat（需先运行 MEOS 和 EOS）
```

**步骤二：批量生成所有权重组合并绘图**

打开 `paint_Data.m`，解除 `%% 生成数据` 区块（第 52–82 行）的注释后运行。
已有预计算结果时可跳过此步，直接运行 `paint_Data.m` 查看图表。

### 全局参数配置

所有实验参数集中在 `global_parameters_block.m`：

```matlab
% 用户偏好
ordertime = 60;             % 任务下单时刻
Time_required_max = 800;    % 最大允许完成时间
Cost_required_max = 7000;   % 最大允许成本
Quality_required_min = 0.6; % 最低质量要求
w_Quality = 0.34;           % 质量权重
w_Cost = 0.33;              % 成本权重
w_Time = 0.33;              % 时间权重

% 算法参数
population_size = 50;
gen_max = 10000;
cross_probability = 0.9;
mutation_probability = 0.05;
```

切换数据集：修改 `global_parameters_block.m` 中 `file_path` 的文件名（见下方数据集说明）。

## 仿真数据集

### 可扩展性实验数据集（主要数据集）

`SimulationDataset/scale_nN_mM.xlsx`，其中 **N = 子任务数，M = 候选服务数**。

批量生成脚本：`SimulationDataset/batch_generate_scale_datasets.m`

| 文件 | 子任务数 N | 候选服务数 M | 用途 |
|------|----------|------------|------|
| `scale_n10_m5.xlsx` | 10 | 5 | **主实验数据集**（默认）|
| `scale_n10_m10.xlsx` | 10 | 10 | 变 M 组 / 变 N 组共享基准 |
| `scale_n10_m15.xlsx` | 10 | 15 | 变 M 组 |
| `scale_n10_m20.xlsx` | 10 | 20 | 变 M 组 |
| `scale_n5_m10.xlsx` | 5 | 10 | 变 N 组 |
| `scale_n15_m10.xlsx` | 15 | 10 | 变 N 组 |
| `scale_n20_m10.xlsx` | 20 | 10 | 变 N 组 |

### 历史数据集（保留参考）

`SimulationDataset/simulationData52.xlsx`（5 个子任务，第 2 实例，每个子任务 5 个候选服务）

## 实验结果文件

结果按规模存放在 `outputs_nN_mM/` 目录下，以权重组合命名：

| 后缀 | w_Quality | w_Cost | w_Time | 含义 |
|------|-----------|--------|--------|------|
| `333` | 0.34 | 0.33 | 0.33 | 均衡权重 |
| `550` | 0.5 | 0.5 | 0 | 质量+成本优先 |
| `505` | 0.5 | 0 | 0.5 | 质量+时间优先 |
| `055` | 0 | 0.5 | 0.5 | 成本+时间优先 |
| `100` | 1 | 0 | 0 | 仅质量 |
| `010` | 0 | 1 | 0 | 仅成本 |
| `001` | 0 | 0 | 1 | 仅时间 |

示例：`outputs_n10_m5/Data_TCHS-333.mat` 对应规模 n=10 m=5、均衡权重下 TCHS 的结果。

每个 `.mat` 文件存储完整的历代种群信息、帕累托前沿、时间调度信息及 HV 历史。

## 代码结构

```
├── Main_FSGS.m                       # FSGS 策略主程序（NSGA-II + MOS 调度）
├── Main_MEOS.m                       # MEOS 策略主程序（NSGA-II + 反向能耗调度）
├── Main_EOS.m                        # EOS 策略主程序（NSGA-II + 正向能耗调度）
├── Main_ESGS_Forward.m               # ESGS-Forward 策略主程序（NSGA-II + 正向能耗调度变体）
├── Main_MOEAD.m                      # MOEA/D 对比算法主程序
├── Main_MOPSO.m                      # MOPSO 对比算法主程序
├── Main_TCHS.m                       # TCHS 后处理主程序（MEOS ∪ EOS 联合前沿）
├── paint_Data.m                      # 批量生成数据与多算法对比绘图
├── global_parameters_block.m         # 全局参数入口
│
├── 核心算法（调度策略）
│   ├── get_cohesion.m                # 任务衔接度计算（论文核心）
│   ├── preheating_energy.m           # 实际预热能耗计算
│   ├── scheduling_Makespan.m         # FSGS 调度（纯正向 MOS）
│   ├── scheduling_Makespan_Energy.m  # MEOS 调度（正向确定 makespan + 反向能耗优化）
│   ├── scheduling_Energy.m           # EOS 调度（正向贴近右端，能耗优先）
│   └── scheduling_Makespan_Energy_Forward.m  # ESGS-Forward 调度（正向确定 makespan + 正向能耗优化）
│
├── NSGA-II 框架
│   ├── cross.m                       # 交叉算子
│   ├── mutate.m                      # 变异算子
│   ├── combine.m                     # 种群合并
│   ├── pareto_front.m                # Pareto 前沿分层
│   ├── crowd_distance.m              # 拥挤距离计算
│   └── select_population.m           # 种群选择
│
├── 适应度评估
│   ├── criteria.m                    # QoS 指标计算（Quality / Cost / Time）
│   ├── fitness_Energy.m              # 上层适应度（能耗）
│   ├── fitness_QoS.m                 # 下层适应度（QoS）
│   ├── dimensionless_Energy.m        # 能耗无量纲化
│   ├── dimensionless_QoS.m           # QoS 无量纲化
│   └── compute_hv.m                  # 超体积指标（HV）计算
│
├── 辅助函数
│   ├── logistics.m                   # 物流时间与成本计算
│   ├── Start_End_logistics.m         # 物流时间窗口计算
│   ├── get_occupancy.m               # 服务占用时段生成
│   └── extract_data.m                # 从 xlsx 读取仿真数据
│
├── 可视化
│   ├── paint_gantt.m                 # 甘特图
│   └── paint_pareto_dynamically.m    # 动态 Pareto 前沿图
│
├── SimulationDataset/                # 仿真数据集
│   ├── scale_nN_mM.xlsx              # 可扩展性实验数据集（主要）
│   ├── simulationData52.xlsx         # 历史数据集（保留参考）
│   ├── batch_generate_scale_datasets.m  # 批量生成数据集脚本
│   └── generateDataset.m             # 单次数据集生成脚本
│
└── outputs_nN_mM/                    # 实验结果（按规模分目录）
    └── Data_{ALGO}-{postfix}.mat     # 各算法 × 各权重组合的预计算结果
```
