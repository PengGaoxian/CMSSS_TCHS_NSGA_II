%% 代码功能：从现有数据集中，计算服务组合的最优选择，无服务占用调度情况，评价指标为：Time（服务时间)、Cost（服务成本）、Q（服务质量）
tic
clear
clc
global_parameters_block
load('weight_current')

%% 算法变量
Individual_best = zeros(gen_max,subtask_num); % 每一代的最优个体存放变量
Individual_best_Start_candidate_service = zeros(gen_max,subtask_num); % 每一代的最优个体的服务开始时间
Individual_best_End_candidate_service = zeros(gen_max,subtask_num); % 每一代最优个体的服务结束时间
Individual_best_Start_logistic = zeros(gen_max,subtask_num); % 每一代最优个体的物流开始时间
Individual_best_End_logistic = zeros(gen_max,subtask_num); % 每一代最优个体的物流结束时间
Individual_best_Fitness = zeros(gen_max,1); % 每一代最优个体的适应度值

Populations = cell(gen_max,1); % 存放各代种群个体
Populations_front_num = cell(gen_max,1); % 存放各代种群个体的前沿编号
Populations_Fitness_value = cell(gen_max,1); % 存放各代种群个体的目标值
Populations_front = cell(gen_max,1); % 存放各代种群最前沿个体
Populations_front_Fitness_value = cell(gen_max,1); % 存放各代种群最前沿个体的目标值
Populations_front_Start_candidate_service = cell(gen_max,1); % 存放各代种群最前沿个体的服务开始时间
Populations_front_End_candidate_service = cell(gen_max,1); % 存放各代种群最前沿个体的服务结束时间
Populations_front_Start_logistics = cell(gen_max,1); % 存放各代种群最前沿个体的物流开始时间
Populations_front_End_logistics = cell(gen_max,1); % 存放各代种群最前沿个体的物流结束时间
% 迭代循环变量
gen = 1;

%% 种群随机初始化
Population = randi(candidate_service_num, population_size, subtask_num);

while(gen <= gen_max)
    %% 优化步骤
    Population_crossed = cross(Population,cross_probability); % 交叉
    Population_mutated = mutate(Population,mutation_probability,candidate_service_num); % 变异
    Population_combined = combine(Population,Population_crossed,Population_mutated); % 合并原始、交叉、变异种群的个体
    
    %% 求解Population_combined种群的适应度
    [Tl,Cl] = logistics(Population_combined,Distance_cell,T_unit_dist,C_unit_dist);% 计算种群中每个个体的物流时间和物流成本
    [Start_candidate_service,End_candidate_service] = scheduling_Makespan(Population_combined,Ts,Idle,ordertime,Time_required_max,Tl); % 计算种群中每个个体中候选服务完成子任务的时间
    [Start_logistics,End_logistics] = Start_End_logistics(End_candidate_service,Tl); % 计算种群中每个个体对应的子任务的运输开始时间和运输结束时间
    
    %% 计算Population_combined种群的上层适应度
    E = preheating_energy(Eh,Population_combined,Th,Tc,Idle,Start_candidate_service,End_candidate_service); % 各候选服务总的实际预热能耗
    Energy = sum(E,2); % 种群中个体的总的预热能耗
    Energy_dimensionless = dimensionless_Energy(Energy,Energy_max); % 对总的预热能耗进行无量纲化
    Fitness_top = fitness_Energy(Energy_dimensionless); % 上层适应度值
    
    %% 计算Population_combined种群的底层适应度
    [Quality,Cost,Time] = criteria(Population_combined,Q,Cs,End_candidate_service,Cl); % 获取种群中每个个体对应的完成质量、完成成本、完成时间
    [Quality_dimensionless,Cost_dimensionless,Time_dimensionless] = dimensionless_QoS(Quality,Cost,Time,Time_required_max,Cost_required_max,Quality_required_min,Time_min,Cost_min,Quality_max); % 数据无量纲化
    Fitness_bottom = fitness_QoS(Quality_dimensionless,Cost_dimensionless,Time_dimensionless,w_Quality,w_Cost,w_Time); % 底层适应度函数值

    %% 计算Population_combined的pareto前沿编号
    Fitness_value = [Fitness_top';Fitness_bottom']'; % 存放种群中个体的目标值
    Inf_index = find(Fitness_value(:,2)==inf); % 找到下层目标为无穷大的行
    Fitness_value(Inf_index,1) = Inf; % 将下层目标为无穷大的行的上层目标也置为无穷大
    front_num = pareto_front(Fitness_value); % 计算种群中个体目标值的帕累托前沿编号
    
    %% 选出下一代种群Population在Population_combined种群中的位置index
    [Population_index,front_index] = select_population(Fitness_value,front_num,population_size);
    
    %% 提取种群信息
    Population = Population_combined(Population_index,:); % 下一代种群
    Population_front_num = front_num(Population_index,:); % 下一代种群的前沿编号
    Population_Fitness_value = Fitness_value(Population_index,:); % 下一代种群的目标值
    
    %% 提取种群前沿信息
    Population_front = Population_combined(front_index,:); % 下一代种群的前沿个体
    Population_front_Fitness_value = Fitness_value(front_index,:); % 下一代种群的前沿个体的目标值
    Population_front_Start_candidate_service = Start_candidate_service(front_index,:);
    Population_front_End_candidate_service = End_candidate_service(front_index,:);
    Population_front_Start_logistics = Start_logistics(front_index,:);
    Population_front_End_logistics = End_logistics(front_index,:);

    %% 存放历代种群个体的信息
    Populations{gen,1} = Population; % 种群个体
    Populations_front_num{gen,1} = Population_front_num; % 种群个体的前沿编号
    Populations_Fitness_value{gen,1} = Population_Fitness_value; % 种群个体的目标值
    %% 存放历代种群前沿个体的信息
    Populations_front{gen,1} = Population_front; % 种群最前沿个体
    Populations_front_Fitness_value{gen,1} = Population_front_Fitness_value; % 种群最前沿个体的目标值
    Populations_front_Start_candidate_service{gen,1} = Population_front_Start_candidate_service; % 种群最前沿个体的服务开始时间
    Populations_front_End_candidate_service{gen,1} = Population_front_End_candidate_service; % 种群最前沿个体的服务结束时间
    Populations_front_Start_logistics{gen,1} = Population_front_Start_logistics; % 种群最前沿个体的物流开始时间
    Populations_front_End_logistics{gen,1} = Population_front_End_logistics; % 种群最前沿个体的物流结束时间
    
    %% 更新代数
    gen = gen + 1;
    disp(gen);
end
toc
%% 画出种群的帕累托前沿图
% paint_pareto_dynamically(Populations_front_num,Populations_Fitness_value,gen_max);

%% 提取最后一代种群的前沿信息
Population_front_last = Populations_front{gen_max,1}; % 最后一代种群的前沿个体
Population_front_last_Fitness_value = Populations_front_Fitness_value{gen_max,1}; % 最后一代种群的前沿目标值
Population_front_last_Start_candidate_service = Populations_front_Start_candidate_service{gen_max,1}; % 最后一代种群的前沿个体的服务开始时间
Population_front_last_End_candidate_service = Populations_front_End_candidate_service{gen_max,1}; % 最后一代种群的前沿个体的服务结束时间
Population_front_last_Start_logistics = Populations_front_Start_logistics{gen_max,1}; % 最后一代种群的前沿个体的物流开始时间
Population_front_last_End_logistics = Populations_front_End_logistics{gen_max,1}; % 最后一代种群前沿个体的物流结束时间
%% 选择第一个个体及其相关数据
Individual = Population_front_last(1,:); % 最后一代种群的前沿个体中的第一个个体
Individual_Start_candidate_service = Population_front_last_Start_candidate_service(1,:);
Individual_End_candidate_service = Population_front_last_End_candidate_service(1,:);
Individual_Start_logistics = Population_front_last_Start_logistics(1,:);
Individual_End_logistics = Population_front_last_End_logistics(1,:);
%% 画出个体的甘特图
% paint_gantt(Individual,Occupancy,Time_elasticity,Individual_Start_candidate_service,Individual_End_candidate_service,Individual_Start_logistics,Individual_End_logistics);
save('Data_FSGS.mat');
