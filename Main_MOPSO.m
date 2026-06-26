% 功能：基于 MOPSO 框架求解云制造服务组合调度问题（FSGS 调度策略）。
%       外部存档维护 Pareto 前沿；粒子以离散整数编码服务选择方案，速度更新后
%       取整映射回合法服务编号区间；调度策略与 Main_FSGS.m 一致（scheduling_Makespan）。
%
% 参考文献：Coello Coello, C.A., Pulido, G.T., & Lechuga, M.S. (2004).
%           Handling multiple objectives with particle swarm optimization.
%           IEEE Transactions on Evolutionary Computation, 8(3), 256-279.
%
% 输入：（无函数输入，由 global_parameters_block 加载至工作区）
%   候选服务数据：Q / Ts / Cs / Th / Tc / Eh / Idle / Occupancy / Distance_cell
%   用户约束：Time_required_max / Cost_required_max / Quality_required_min / ordertime
%   QoS 权重：w_Quality / w_Cost / w_Time
%   归一化基准：Quality_max / Time_min / Cost_min / Energy_max
%   算法超参：population_size / gen_max
%
% 处理流程：
%   1. 初始化粒子位置（离散随机整数）、速度（零向量）、个人最优、外部存档
%   2. 迭代 gen_max 代，每代：
%      a. 惯性权重线性衰减（w_max→w_min）
%      b. 按存档拥挤距离轮盘赌选领袖（每代计算一次，所有粒子共用）
%      c. 对每个粒子：更新速度（截断至±V_max）→ 更新位置（取整截断至 [1,M]）
%      d. 批量评估本代种群适应度
%      e. 按可行性与支配关系更新个人最优
%      f. 合并→去重→非支配→拥挤截断，更新外部存档
%      g. 记录本代种群与 Pareto 前沿（存档）
%   3. 提取最后一代前沿，保存 Data_MOPSO.mat
%
% 输出：（保存至 outputs_nN_mM/Data_MOPSO.mat，供 paint_Data.m 加载绘图）
%   变量命名与 Main_MOEAD.m 完全一致，可直接替换加载

tic
clear
clc

global_parameters_block

%% MOPSO 专用参数
w_max       = 0.9;                        % 惯性权重上界
w_min       = 0.4;                        % 惯性权重下界
c1          = 1.5;                        % 个人学习因子
c2          = 2.0;                        % 社会学习因子
V_max       = candidate_service_num / 2;  % 速度截断上界
archive_max = 100;                        % 外部存档容量上限

N = population_size;

%% 历代记录变量（命名与 Main_MOEAD.m 完全一致）
Populations                               = cell(gen_max, 1);
Populations_front_num                     = cell(gen_max, 1);
Populations_Fitness_value                 = cell(gen_max, 1);
Populations_front                         = cell(gen_max, 1);
Populations_front_Fitness_value           = cell(gen_max, 1);
Populations_front_Start_candidate_service = cell(gen_max, 1);
Populations_front_End_candidate_service   = cell(gen_max, 1);
Populations_front_Start_logistics         = cell(gen_max, 1);
Populations_front_End_logistics           = cell(gen_max, 1);
HV_history = zeros(gen_max, 1);

%% 初始化粒子位置（离散整数）与速度
Position = randi(candidate_service_num, N, subtask_num);
Velocity = zeros(N, subtask_num);

%% 评估初始种群
[Tl, Cl] = logistics(Position, Distance_cell, T_unit_dist, C_unit_dist);
[Start_cs, End_cs] = scheduling_Makespan(Position, Ts, Idle, ordertime, Time_required_max, Tl);
[Start_log, End_log] = Start_End_logistics(End_cs, Tl);

E      = preheating_energy(Eh, Position, Th, Tc, Idle, Start_cs, End_cs);
Energy = sum(E, 2);
Ft     = fitness_Energy(dimensionless_Energy(Energy, Energy_max));

[Qv, Cv, Tv] = criteria(Position, Q, Cs, End_cs, Cl);
[Qd, Cd, Td] = dimensionless_QoS(Qv, Cv, Tv, Time_required_max, Cost_required_max, ...
    Quality_required_min, Time_min, Cost_min, Quality_max);
Fb = fitness_QoS(Qd, Cd, Td, w_Quality, w_Cost, w_Time);

Fitness             = [Ft'; Fb']';
Fitness(Fitness(:,2)==Inf, 1) = Inf;

%% 初始化个人最优（与初始粒子相同）
Pbest_Pos       = Position;
Pbest_Fitness   = Fitness;
Pbest_Start_cs  = Start_cs;
Pbest_End_cs    = End_cs;
Pbest_Start_log = Start_log;
Pbest_End_log   = End_log;

%% 初始化外部存档（取初始非支配前沿）
front0    = pareto_front(Fitness);
arch_init = find(front0 == 1);
Archive           = Position(arch_init, :);
Archive_Fitness   = Fitness(arch_init, :);
Archive_Start_cs  = Start_cs(arch_init, :);
Archive_End_cs    = End_cs(arch_init, :);
Archive_Start_log = Start_log(arch_init, :);
Archive_End_log   = End_log(arch_init, :);

while size(Archive, 1) > archive_max
    n_arc  = size(Archive, 1);
    cd_arc = crowd_distance(Archive_Fitness, ones(n_arc,1), 1);
    cd_arc(isnan(cd_arc)) = 0;
    if all(isinf(cd_arc))
        rm = randi(n_arc);
    else
        tmp = cd_arc; tmp(isinf(tmp)) = Inf;
        [~, rm] = min(tmp);
    end
    keep = setdiff(1:n_arc, rm, 'stable');
    Archive           = Archive(keep, :);
    Archive_Fitness   = Archive_Fitness(keep, :);
    Archive_Start_cs  = Archive_Start_cs(keep, :);
    Archive_End_cs    = Archive_End_cs(keep, :);
    Archive_Start_log = Archive_Start_log(keep, :);
    Archive_End_log   = Archive_End_log(keep, :);
end

%% 主循环
for gen = 1:gen_max
    w = w_max - (w_max - w_min) * gen / gen_max;   % 惯性权重线性衰减

    %% 计算存档拥挤距离（每代一次，所有粒子共用）
    n_arc = size(Archive_Fitness, 1);
    if n_arc > 1
        cd_arc = crowd_distance(Archive_Fitness, ones(n_arc,1), 1);
        cd_arc(isnan(cd_arc)) = 0;
        finite_cd = cd_arc(~isinf(cd_arc));
        if isempty(finite_cd)
            cd_arc(:) = 1;
        else
            cd_arc(isinf(cd_arc)) = max(finite_cd) * 10;
        end
    end

    %% 更新每个粒子的速度与位置
    for i = 1:N
        % 按拥挤距离轮盘赌选领袖
        if n_arc == 1
            leader_idx = 1;
        elseif sum(cd_arc) == 0
            leader_idx = randi(n_arc);
        else
            prob = cd_arc / sum(cd_arc);
            leader_idx = find(rand <= cumsum(prob), 1, 'first');
            if isempty(leader_idx), leader_idx = n_arc; end
        end
        Leader = Archive(leader_idx, :);

        r1 = rand(1, subtask_num);
        r2 = rand(1, subtask_num);
        Velocity(i,:) = w * Velocity(i,:) ...
            + c1 * r1 .* (Pbest_Pos(i,:) - Position(i,:)) ...
            + c2 * r2 .* (Leader          - Position(i,:));
        Velocity(i,:) = max(min(Velocity(i,:), V_max), -V_max);
        new_pos = round(Position(i,:) + Velocity(i,:));
        Position(i,:) = max(min(new_pos, candidate_service_num), 1);
    end

    %% 批量评估本代种群
    [Tl, Cl] = logistics(Position, Distance_cell, T_unit_dist, C_unit_dist);
    [Start_cs, End_cs] = scheduling_Makespan(Position, Ts, Idle, ordertime, Time_required_max, Tl);
    [Start_log, End_log] = Start_End_logistics(End_cs, Tl);

    E      = preheating_energy(Eh, Position, Th, Tc, Idle, Start_cs, End_cs);
    Energy = sum(E, 2);
    Ft     = fitness_Energy(dimensionless_Energy(Energy, Energy_max));

    [Qv, Cv, Tv] = criteria(Position, Q, Cs, End_cs, Cl);
    [Qd, Cd, Td] = dimensionless_QoS(Qv, Cv, Tv, Time_required_max, Cost_required_max, ...
        Quality_required_min, Time_min, Cost_min, Quality_max);
    Fb = fitness_QoS(Qd, Cd, Td, w_Quality, w_Cost, w_Time);

    Fitness             = [Ft'; Fb']';
    Fitness(Fitness(:,2)==Inf, 1) = Inf;

    %% 更新个人最优（可行性优先，其次支配关系，互不支配时 50% 接受）
    for i = 1:N
        new_ok = ~any(isinf(Fitness(i,:)));
        old_ok = ~any(isinf(Pbest_Fitness(i,:)));
        if new_ok && old_ok
            dom_new = all(Fitness(i,:) <= Pbest_Fitness(i,:)) && any(Fitness(i,:) < Pbest_Fitness(i,:));
            dom_old = all(Pbest_Fitness(i,:) <= Fitness(i,:)) && any(Pbest_Fitness(i,:) < Fitness(i,:));
            update  = dom_new || (~dom_old && rand < 0.5);
        else
            update = new_ok && ~old_ok;
        end
        if update
            Pbest_Pos(i,:)       = Position(i,:);
            Pbest_Fitness(i,:)   = Fitness(i,:);
            Pbest_Start_cs(i,:)  = Start_cs(i,:);
            Pbest_End_cs(i,:)    = End_cs(i,:);
            Pbest_Start_log(i,:) = Start_log(i,:);
            Pbest_End_log(i,:)   = End_log(i,:);
        end
    end

    %% 更新外部存档：合并 → 去重 → 非支配 → 超容截断
    Combined_Pos       = [Archive;           Position   ];
    Combined_Fitness   = [Archive_Fitness;   Fitness    ];
    Combined_Start_cs  = [Archive_Start_cs;  Start_cs   ];
    Combined_End_cs    = [Archive_End_cs;    End_cs     ];
    Combined_Start_log = [Archive_Start_log; Start_log  ];
    Combined_End_log   = [Archive_End_log;   End_log    ];

    [Combined_Fitness, ia] = unique(Combined_Fitness, 'rows', 'stable');
    Combined_Pos       = Combined_Pos(ia, :);
    Combined_Start_cs  = Combined_Start_cs(ia, :);
    Combined_End_cs    = Combined_End_cs(ia, :);
    Combined_Start_log = Combined_Start_log(ia, :);
    Combined_End_log   = Combined_End_log(ia, :);

    front_arc = pareto_front(Combined_Fitness);
    nd_idx    = find(front_arc == 1);
    Archive           = Combined_Pos(nd_idx, :);
    Archive_Fitness   = Combined_Fitness(nd_idx, :);
    Archive_Start_cs  = Combined_Start_cs(nd_idx, :);
    Archive_End_cs    = Combined_End_cs(nd_idx, :);
    Archive_Start_log = Combined_Start_log(nd_idx, :);
    Archive_End_log   = Combined_End_log(nd_idx, :);

    while size(Archive, 1) > archive_max
        n_arc  = size(Archive, 1);
        cd_arc = crowd_distance(Archive_Fitness, ones(n_arc,1), 1);
        cd_arc(isnan(cd_arc)) = 0;
        if all(isinf(cd_arc))
            rm = randi(n_arc);
        else
            tmp = cd_arc; tmp(isinf(tmp)) = Inf;
            [~, rm] = min(tmp);
        end
        keep = setdiff(1:n_arc, rm, 'stable');
        Archive           = Archive(keep, :);
        Archive_Fitness   = Archive_Fitness(keep, :);
        Archive_Start_cs  = Archive_Start_cs(keep, :);
        Archive_End_cs    = Archive_End_cs(keep, :);
        Archive_Start_log = Archive_Start_log(keep, :);
        Archive_End_log   = Archive_End_log(keep, :);
    end

    %% 记录本代信息（Populations_front 对应外部存档，即维护的 Pareto 前沿）
    front_num = pareto_front(Fitness);
    Populations{gen,1}                               = Position;
    Populations_front_num{gen,1}                     = front_num;
    Populations_Fitness_value{gen,1}                 = Fitness;
    Populations_front{gen,1}                         = Archive;
    Populations_front_Fitness_value{gen,1}           = Archive_Fitness;
    Populations_front_Start_candidate_service{gen,1} = Archive_Start_cs;
    Populations_front_End_candidate_service{gen,1}   = Archive_End_cs;
    Populations_front_Start_logistics{gen,1}         = Archive_Start_log;
    Populations_front_End_logistics{gen,1}           = Archive_End_log;
    HV_history(gen) = compute_hv(Populations_front_Fitness_value{gen,1}, [1.1, 1.1]);

    disp(gen);
end
Run_Time = toc;

%% 提取最后一代前沿信息（格式与 Main_MOEAD.m 完全一致）
Population_front_last                         = Populations_front{gen_max,1};
Population_front_last_Fitness_value           = Populations_front_Fitness_value{gen_max,1};
Population_front_last_Start_candidate_service = Populations_front_Start_candidate_service{gen_max,1};
Population_front_last_End_candidate_service   = Populations_front_End_candidate_service{gen_max,1};
Population_front_last_Start_logistics         = Populations_front_Start_logistics{gen_max,1};
Population_front_last_End_logistics           = Populations_front_End_logistics{gen_max,1};

%% 提取前沿点指标
QoS_Fitness    = Population_front_last_Fitness_value(:,2);
Energy_Fitness = Population_front_last_Fitness_value(:,1);
[~, Cl_front]  = logistics(Population_front_last, Distance_cell, T_unit_dist, C_unit_dist);
[Quality, Cost, Time] = criteria(Population_front_last, Q, Cs, ...
    Population_front_last_End_candidate_service, Cl_front);
E_front    = preheating_energy(Eh, Population_front_last, Th, Tc, Idle, ...
    Population_front_last_Start_candidate_service, Population_front_last_End_candidate_service);
Energy_Raw = sum(E_front, 2);
HV         = compute_hv(Population_front_last_Fitness_value, [1.1, 1.1]);

Individual                         = Population_front_last(1,:);
Individual_Start_candidate_service = Population_front_last_Start_candidate_service(1,:);
Individual_End_candidate_service   = Population_front_last_End_candidate_service(1,:);
Individual_Start_logistics         = Population_front_last_Start_logistics(1,:);
Individual_End_logistics           = Population_front_last_End_logistics(1,:);

outDir = fullfile(fileparts(mfilename('fullpath')), sprintf('outputs_n%d_m%d', subtask_num, candidate_service_num));
if ~exist(outDir, 'dir'), mkdir(outDir); end
save(fullfile(outDir, 'Data_MOPSO.mat'));
