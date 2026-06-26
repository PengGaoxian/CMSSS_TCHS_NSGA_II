% 功能：从扩展种群 Population_combined 中按 NSGA-II 精英选择策略
%       选出 population_size 个个体构成下一代种群，同时返回第 1 层前沿的个体索引。
%
% 输入：
%   Fitness_value    - 目标值矩阵 [N × 2]，N 为扩展种群大小
%   front_num        - 各个体的 Pareto 层级编号列向量 [N × 1]，由 pareto_front 计算
%   population_size  - 目标种群大小
%
% 处理流程：
%   1. 取第 1 层前沿索引作为 front_index（用于记录历代最优前沿）
%   2. 从第 1 层开始累计计算前 k 层的个体总数，找到恰好使累计数 ≥ population_size
%      的最小层级 front_num_ge
%   3a. 若累计数 > population_size（最后一层只能部分纳入）：
%       · 将前 front_num_ge-1 层的所有个体直接填入 Population_index
%       · 对第 front_num_ge 层调用 crowd_distance 计算拥挤距离，
%         按拥挤距离降序排列后取前 (population_size - 已有数量) 个个体补齐
%   3b. 若累计数 == population_size：
%       将前 front_num_ge 层的所有个体直接作为 Population_index
%
% 输出：
%   Population_index - 下一代种群个体在 Population_combined 中的行索引 [population_size × 1]
%   front_index      - 第 1 层 Pareto 前沿个体在 Population_combined 中的行索引
function [Population_index,front_index] = select_population(Fitness_value,front_num,population_size)
    Population_index = zeros(population_size,1);
    front_index = find(front_num==1);
    front_num_ge = 1;
    % 判断前front_num个前沿个体复制到下一代
    while true
        nums_ge_population_size = numel(front_num,front_num<=front_num_ge); % 计算前front_index个前沿中的个体数量
        if nums_ge_population_size >= population_size
            break;
        end
        front_num_ge = front_num_ge + 1;
    end
    if nums_ge_population_size > population_size
        front_num_lt = front_num_ge - 1;
        nums_lt_population_size = numel(front_num,front_num<=front_num_lt);
        % 获取Population的个体在Population_combined种群中的序号(前front_num个前沿)
        Population_index(1:nums_lt_population_size,1) = find(front_num<=front_num_lt);
        % 补充种群
        Population_combined_index_for_front_n = find(front_num == front_num_ge); % 记录第front_num_ge个前沿的个体编号
        distance_value = crowd_distance(Fitness_value,front_num,front_num_ge); % 计算拥挤距离
        combine_distance_index_for_front_n = [distance_value';Population_combined_index_for_front_n']'; % 合并距离和序号
        Population_combined_index_for_front_n = sortrows(combine_distance_index_for_front_n,'descend'); % 按拥挤距离降序排列第front_num个前沿上的个体
        population_vacancy_size = population_size - nums_lt_population_size; % 种群中缺少的个体数量
        Population_filled_index = Population_combined_index_for_front_n(1:population_vacancy_size,2); % 填补种群的个体
        % 补充Population中空缺的序号，序号从Population_combined中获得
        Population_index(nums_lt_population_size+1:population_size,1) = Population_filled_index; 
    elseif nums_ge_population_size == population_size
        % 获取Population的个体在Population_combined种群中的序号
        Population_index = find(front_num<=front_num_ge);
    end
end

