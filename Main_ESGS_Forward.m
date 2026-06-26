% 功能：基于 NSGA-II 框架求解云制造服务组合调度问题（ESGS-Forward 策略）。
%       采用双层目标：上层为 Provider 侧预热能耗最小化，下层为 Demander 侧 QoS 综合最优。
%       调度采用能耗感知的正向遍历策略（scheduling_Makespan_Energy_Forward），
%       在确定 makespan 后从前向后将服务执行窗口向衔接度更高的位置移动以降低预热能耗。
%
% 输入：（无函数输入，由 global_parameters_block 脚本加载至工作区）
%   候选服务数据：Q / Ts / Cs / Th / Tc / Eh / Idle / Occupancy / Distance_cell
%   用户约束：Time_required_max / Cost_required_max / Quality_required_min / ordertime
%   QoS 权重：w_Quality / w_Cost / w_Time
%   归一化基准：Quality_max / Time_min / Cost_min / Energy_max
%   算法超参：population_size / gen_max / cross_probability / mutation_probability
%
% 处理流程：
%   1. 加载全局参数（global_parameters_block）
%   2. 初始化记录变量与随机初始种群
%   3. 迭代 gen_max 代，每代执行：
%      a. 交叉、变异、合并生成扩展种群 Population_combined
%      b. 物流计算（logistics）→ 正向能耗调度（scheduling_Makespan_Energy_Forward）→ 物流时段提取
%      c. 上层适应度：预热能耗 → 无量纲化 → fitness_Energy
%      d. 下层适应度：QoS 指标（criteria）→ 无量纲化 → fitness_QoS
%      e. 双目标 Pareto 排序（pareto_front），不可行解（下层 Inf）同步将上层置 Inf
%      f. 选择下一代种群（select_population），提取前沿个体及时间信息
%      g. 存入历代记录 cell
%   4. 提取最后一代 Pareto 前沿第一个个体
%   5. 保存全部工作区变量至 Data_ESGS_Forward.mat
%
% 输出：（保存至 Data_ESGS_Forward.mat，供 paint_Data.m 加载绘图）
%   Populations / Populations_Fitness_value / Populations_front_num — 历代种群记录
%   Populations_front / Populations_front_Fitness_value            — 历代前沿记录
%   Populations_front_Start/End_candidate_service / _logistics     — 历代前沿时间记录
%   Population_front_last 及其衍生变量                             — 最后一代前沿完整信息

tic
clear
clc

global_parameters_block

%% 算法变量
Individual_best = zeros(gen_max,subtask_num);
Individual_best_Start_candidate_service = zeros(gen_max,subtask_num);
Individual_best_End_candidate_service = zeros(gen_max,subtask_num);
Individual_best_Start_logistic = zeros(gen_max,subtask_num);
Individual_best_End_logistic = zeros(gen_max,subtask_num);
Individual_best_Fitness = zeros(gen_max,1);
HV_history = zeros(gen_max, 1);

Populations = cell(gen_max,1);
Populations_front_num = cell(gen_max,1);
Populations_Fitness_value = cell(gen_max,1);
Populations_front = cell(gen_max,1);
Populations_front_Fitness_value = cell(gen_max,1);
Populations_front_Start_candidate_service = cell(gen_max,1);
Populations_front_End_candidate_service = cell(gen_max,1);
Populations_front_Start_logistics = cell(gen_max,1);
Populations_front_End_logistics = cell(gen_max,1);
gen = 1;

%% 种群随机初始化
Population = randi(candidate_service_num, population_size, subtask_num);

while(gen <= gen_max)
    %% 优化步骤
    Population_crossed = cross(Population,cross_probability);
    Population_mutated = mutate(Population,mutation_probability,candidate_service_num);
    Population_combined = combine(Population,Population_crossed,Population_mutated);

    %% 对Population_combined种群进行调度
    [Tl,Cl] = logistics(Population_combined,Distance_cell,T_unit_dist,C_unit_dist);
    [Start_candidate_service,End_candidate_service] = scheduling_Makespan_Energy_Forward(Population_combined,Th,Tc,Ts,Idle,ordertime,Time_required_max,Tl);
    [Start_logistics,End_logistics] = Start_End_logistics(End_candidate_service,Tl);

    %% 计算Population_combined种群的上层适应度（Provider：Energy）
    E = preheating_energy(Eh,Population_combined,Th,Tc,Idle,Start_candidate_service,End_candidate_service);
    Energy = sum(E,2);
    Energy_dimensionless = dimensionless_Energy(Energy,Energy_max);
    Fitness_top = fitness_Energy(Energy_dimensionless);

    %% 计算Population_combined种群的底层适应度（Demander：Time、Cost、Quality）
    [Quality,Cost,Time] = criteria(Population_combined,Q,Cs,End_candidate_service,Cl);
    [Quality_dimensionless,Cost_dimensionless,Time_dimensionless] = dimensionless_QoS(Quality,Cost,Time,Time_required_max,Cost_required_max,Quality_required_min,Time_min,Cost_min,Quality_max);
    Fitness_bottom = fitness_QoS(Quality_dimensionless,Cost_dimensionless,Time_dimensionless,w_Quality,w_Cost,w_Time);

    %% 计算Population_combined的pareto前沿编号
    Fitness_value = [Fitness_top';Fitness_bottom']';
    Inf_index = find(Fitness_value(:,2)==inf);
    Fitness_value(Inf_index,1) = Inf;
    front_num = pareto_front(Fitness_value);

    %% 选出下一代种群Population在Population_combined种群中的位置index
    [Population_index,front_index] = select_population(Fitness_value,front_num,population_size);

    %% 提取种群信息
    Population = Population_combined(Population_index,:);
    Population_front_num = front_num(Population_index,:);
    Population_Fitness_value = Fitness_value(Population_index,:);

    %% 提取种群前沿信息
    Population_front = Population_combined(front_index,:);
    Population_front_Fitness_value = Fitness_value(front_index,:);
    Population_front_Start_candidate_service = Start_candidate_service(front_index,:);
    Population_front_End_candidate_service = End_candidate_service(front_index,:);
    Population_front_Start_logistics = Start_logistics(front_index,:);
    Population_front_End_logistics = End_logistics(front_index,:);

    %% 存放历代种群个体的信息
    Populations{gen,1} = Population;
    Populations_front_num{gen,1} = Population_front_num;
    Populations_Fitness_value{gen,1} = Population_Fitness_value;
    %% 存放历代种群前沿个体的信息
    Populations_front{gen,1} = Population_front;
    Populations_front_Fitness_value{gen,1} = Population_front_Fitness_value;
    Populations_front_Start_candidate_service{gen,1} = Population_front_Start_candidate_service;
    Populations_front_End_candidate_service{gen,1} = Population_front_End_candidate_service;
    Populations_front_Start_logistics{gen,1} = Population_front_Start_logistics;
    Populations_front_End_logistics{gen,1} = Population_front_End_logistics;
    HV_history(gen) = compute_hv(Populations_front_Fitness_value{gen,1}, [1.1, 1.1]);

    %% 更新代数
    gen = gen + 1;
    disp(gen);
end
Run_Time = toc;

%% 提取最后一代种群的前沿信息
Population_front_last = Populations_front{gen_max,1};
Population_front_last_Fitness_value = Populations_front_Fitness_value{gen_max,1};
Population_front_last_Start_candidate_service = Populations_front_Start_candidate_service{gen_max,1};
Population_front_last_End_candidate_service = Populations_front_End_candidate_service{gen_max,1};
Population_front_last_Start_logistics = Populations_front_Start_logistics{gen_max,1};
Population_front_last_End_logistics = Populations_front_End_logistics{gen_max,1};

%% 提取最后一代前沿点指标（直接存入 .mat，供 paint_Data.m 使用）
QoS_Fitness    = Population_front_last_Fitness_value(:,2);
Energy_Fitness = Population_front_last_Fitness_value(:,1);
Quality        = Quality(front_index);
Cost           = Cost(front_index);
Time           = Time(front_index);
Energy_Raw     = Energy(front_index);
HV             = compute_hv(Population_front_last_Fitness_value, [1.1, 1.1]);

%% 选择第一个个体及其相关数据
Individual = Population_front_last(1,:);
Individual_Start_candidate_service = Population_front_last_Start_candidate_service(1,:);
Individual_End_candidate_service = Population_front_last_End_candidate_service(1,:);
Individual_Start_logistics = Population_front_last_Start_logistics(1,:);
Individual_End_logistics = Population_front_last_End_logistics(1,:);
%% 画出个体的甘特图
% paint_gantt(Individual,Occupancy,Time_elasticity,Individual_Start_candidate_service,Individual_End_candidate_service,Individual_Start_logistics,Individual_End_logistics);
outDir = fullfile(fileparts(mfilename('fullpath')), sprintf('outputs_n%d_m%d', subtask_num, candidate_service_num));
if ~exist(outDir, 'dir'), mkdir(outDir); end
save(fullfile(outDir, 'Data_ESGS_Forward.mat'));
