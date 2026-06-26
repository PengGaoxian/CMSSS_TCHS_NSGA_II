% 功能：基于 MOEA/D 框架求解云制造服务组合调度问题（FSGS 调度策略）。
%       采用 Tchebycheff 分解将双目标问题转化为 N 个加权单目标子问题，
%       通过邻域协作进化机制驱动种群向 Pareto 前沿收敛。
%       调度采用 FSGS 惯例策略（scheduling_Makespan），与 NSGA-II 基线保持一致，
%       以隔离优化器变量、验证 TCHS 调度策略的独立贡献。
%
% 参考文献：Zhang, Q. & Li, H. (2007). MOEA/D: A Multiobjective Evolutionary Algorithm
%           Based on Decomposition. IEEE Transactions on Evolutionary Computation, 11(6), 712-731.
%
% 输入：（无函数输入，由 global_parameters_block 加载至工作区）
%   候选服务数据：Q / Ts / Cs / Th / Tc / Eh / Idle / Occupancy / Distance_cell
%   用户约束：Time_required_max / Cost_required_max / Quality_required_min / ordertime
%   QoS 权重：w_Quality / w_Cost / w_Time
%   归一化基准：Quality_max / Time_min / Cost_min / Energy_max
%   算法超参：population_size / gen_max / cross_probability / mutation_probability
%
% 处理流程：
%   1. 生成 N=population_size 个均匀权重向量，构建 T=ceil(0.1N) 邻域矩阵
%   2. 随机初始化种群，评估初始适应度，初始化理想点 z*
%   3. 迭代 gen_max 代，每代对 N 个子问题各生成1个后代：
%      a. 从邻域随机选2个父代 → 交叉 + 变异
%      b. FSGS 调度 → 计算双目标适应度（不可行解上层置 Inf）
%      c. 更新理想点 z*（仅可行解参与）
%      d. Tchebycheff 聚合比较，改善邻域中的个体
%      e. 记录本代 Pareto 前沿
%   4. 提取最后一代 Pareto 前沿，保存 Data_MOEAD.mat
%
% 输出：（保存至 outputs/Data_MOEAD.mat，供 paint_Data.m 加载绘图）
%   变量命名与 Main_FSGS.m 完全一致，可直接替换加载

tic
clear
clc

global_parameters_block

%% MOEA/D 专用参数
N = population_size;              % 子问题数 = 权重向量数
T = max(2, ceil(0.1 * N));       % 邻域大小（标准取 10%）

%% 生成均匀权重向量 [N × 2]，端点为 (1,0) 和 (0,1)
lambda = [(0:N-1)' / (N-1), (N-1:-1:0)' / (N-1)];

%% 构建邻域矩阵 B [N × T]：B(i,:) 为 lambda_i 的 T 个最近邻索引
B = zeros(N, T);
for i = 1:N
    dist = sum((lambda - lambda(i,:)).^2, 2);
    [~, idx] = sort(dist);
    B(i,:) = idx(1:T)';
end

%% 历代记录变量
Populations                                    = cell(gen_max, 1);
Populations_front_num                          = cell(gen_max, 1);
Populations_Fitness_value                      = cell(gen_max, 1);
Populations_front                              = cell(gen_max, 1);
Populations_front_Fitness_value                = cell(gen_max, 1);
Populations_front_Start_candidate_service      = cell(gen_max, 1);
Populations_front_End_candidate_service        = cell(gen_max, 1);
Populations_front_Start_logistics              = cell(gen_max, 1);
Populations_front_End_logistics                = cell(gen_max, 1);
HV_history = zeros(gen_max, 1);

%% 随机初始化种群 [N × subtask_num]
Population = randi(candidate_service_num, N, subtask_num);

%% 评估初始种群
[Tl_init, Cl_init] = logistics(Population, Distance_cell, T_unit_dist, C_unit_dist);
[Start_cs_init, End_cs_init] = scheduling_Makespan(Population, Ts, Idle, ordertime, Time_required_max, Tl_init);
[Start_log_init, End_log_init] = Start_End_logistics(End_cs_init, Tl_init);

E_init = preheating_energy(Eh, Population, Th, Tc, Idle, Start_cs_init, End_cs_init);
Energy_init = sum(E_init, 2);
Fitness_top_init = fitness_Energy(dimensionless_Energy(Energy_init, Energy_max));

[Q_init, Cost_init, Time_init] = criteria(Population, Q, Cs, End_cs_init, Cl_init);
[Qd_init, Cd_init, Td_init] = dimensionless_QoS(Q_init, Cost_init, Time_init, ...
    Time_required_max, Cost_required_max, Quality_required_min, Time_min, Cost_min, Quality_max);
Fitness_bottom_init = fitness_QoS(Qd_init, Cd_init, Td_init, w_Quality, w_Cost, w_Time);

Fitness_value = [Fitness_top_init'; Fitness_bottom_init']';
Inf_idx = find(Fitness_value(:,2) == Inf);
Fitness_value(Inf_idx, 1) = Inf;

%% 维护种群时序信息（随个体替换同步更新）
Pop_Start_cs  = Start_cs_init;
Pop_End_cs    = End_cs_init;
Pop_Start_log = Start_log_init;
Pop_End_log   = End_log_init;

%% 初始化理想点 z*：各目标的最小已知值
feasible_mask = Fitness_value(:,1) < Inf;
if any(feasible_mask)
    z_star = min(Fitness_value(feasible_mask, :), [], 1);
else
    z_star = [0, 0];
end

%% 主循环
for gen = 1:gen_max

    for i = 1:N
        %% 从邻域 B(i) 随机选2个父代
        perm_idx = randperm(T, 2);
        p1 = B(i, perm_idx(1));
        p2 = B(i, perm_idx(2));
        parent_pair = Population([p1, p2], :);

        %% 交叉 + 变异生成后代（复用现有算子）
        offspring_crossed = cross(parent_pair, cross_probability);
        offspring = mutate(offspring_crossed(1,:), mutation_probability, candidate_service_num);

        %% 评估后代（FSGS 调度）
        [Tl_y, Cl_y] = logistics(offspring, Distance_cell, T_unit_dist, C_unit_dist);
        [Start_cs_y, End_cs_y] = scheduling_Makespan(offspring, Ts, Idle, ordertime, Time_required_max, Tl_y);
        [Start_log_y, End_log_y] = Start_End_logistics(End_cs_y, Tl_y);

        E_y = preheating_energy(Eh, offspring, Th, Tc, Idle, Start_cs_y, End_cs_y);
        f1 = fitness_Energy(dimensionless_Energy(sum(E_y, 2), Energy_max));

        [Q_y, Cost_y, Time_y] = criteria(offspring, Q, Cs, End_cs_y, Cl_y);
        [Qd_y, Cd_y, Td_y] = dimensionless_QoS(Q_y, Cost_y, Time_y, ...
            Time_required_max, Cost_required_max, Quality_required_min, Time_min, Cost_min, Quality_max);
        f2 = fitness_QoS(Qd_y, Cd_y, Td_y, w_Quality, w_Cost, w_Time);

        if f2 == Inf
            f1 = Inf;
        end
        y_fitness = [f1, f2];

        %% 更新理想点（仅可行解参与）
        if f1 < Inf
            z_star = min(z_star, y_fitness);
        end

        %% Tchebycheff 聚合比较：更新邻域中被改善的个体
        for k = 1:T
            j = B(i, k);
            lj = lambda(j,:);

            if any(isinf(y_fitness))
                g_y = Inf;
            else
                g_y = max(lj .* abs(y_fitness - z_star));
            end

            fj = Fitness_value(j,:);
            if any(isinf(fj))
                g_xj = Inf;
            else
                g_xj = max(lj .* abs(fj - z_star));
            end

            if g_y <= g_xj
                Population(j,:)    = offspring;
                Fitness_value(j,:) = y_fitness;
                Pop_Start_cs(j,:)  = Start_cs_y;
                Pop_End_cs(j,:)    = End_cs_y;
                Pop_Start_log(j,:) = Start_log_y;
                Pop_End_log(j,:)   = End_log_y;
            end
        end
    end

    %% 记录本代 Pareto 前沿
    front_num   = pareto_front(Fitness_value);
    front_index = find(front_num == 1);

    Populations{gen,1}                                = Population;
    Populations_front_num{gen,1}                      = front_num;
    Populations_Fitness_value{gen,1}                  = Fitness_value;
    Populations_front{gen,1}                          = Population(front_index,:);
    Populations_front_Fitness_value{gen,1}            = Fitness_value(front_index,:);
    Populations_front_Start_candidate_service{gen,1}  = Pop_Start_cs(front_index,:);
    Populations_front_End_candidate_service{gen,1}    = Pop_End_cs(front_index,:);
    Populations_front_Start_logistics{gen,1}          = Pop_Start_log(front_index,:);
    Populations_front_End_logistics{gen,1}            = Pop_End_log(front_index,:);
    HV_history(gen) = compute_hv(Populations_front_Fitness_value{gen,1}, [1.1, 1.1]);

    disp(gen);
end
Run_Time = toc;

%% 提取最后一代前沿信息（格式与 Main_FSGS.m 一致）
Population_front_last                         = Populations_front{gen_max,1};
Population_front_last_Fitness_value           = Populations_front_Fitness_value{gen_max,1};
Population_front_last_Start_candidate_service = Populations_front_Start_candidate_service{gen_max,1};
Population_front_last_End_candidate_service   = Populations_front_End_candidate_service{gen_max,1};
Population_front_last_Start_logistics         = Populations_front_Start_logistics{gen_max,1};
Population_front_last_End_logistics           = Populations_front_End_logistics{gen_max,1};

%% 提取最后一代前沿点指标（直接存入 .mat，供 paint_Data.m 使用）
QoS_Fitness    = Population_front_last_Fitness_value(:,2);
Energy_Fitness = Population_front_last_Fitness_value(:,1);
[~, Cl_front]  = logistics(Population_front_last, Distance_cell, T_unit_dist, C_unit_dist);
[Quality, Cost, Time] = criteria(Population_front_last, Q, Cs, Population_front_last_End_candidate_service, Cl_front);
E_front        = preheating_energy(Eh, Population_front_last, Th, Tc, Idle, Population_front_last_Start_candidate_service, Population_front_last_End_candidate_service);
Energy_Raw     = sum(E_front, 2);
HV             = compute_hv(Population_front_last_Fitness_value, [1.1, 1.1]);

Individual                             = Population_front_last(1,:);
Individual_Start_candidate_service     = Population_front_last_Start_candidate_service(1,:);
Individual_End_candidate_service       = Population_front_last_End_candidate_service(1,:);
Individual_Start_logistics             = Population_front_last_Start_logistics(1,:);
Individual_End_logistics               = Population_front_last_End_logistics(1,:);

outDir = fullfile(fileparts(mfilename('fullpath')), sprintf('outputs_n%d_m%d', subtask_num, candidate_service_num));
if ~exist(outDir, 'dir'), mkdir(outDir); end
save(fullfile(outDir, 'Data_MOEAD.mat'));
