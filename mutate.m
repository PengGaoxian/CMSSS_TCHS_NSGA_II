% 功能：对种群执行片段随机重置变异，以一定概率对每个个体随机选取一段子任务区间，
%       将该区间内的候选服务序号替换为随机值，增加种群多样性、避免早熟收敛。
%
% 输入：
%   Population            - 原始种群矩阵 [population_size × subtask_num]
%   mutation_probability  - 变异概率（每个个体独立判断）
%   candidate_service_num - 每个子任务的候选服务数量（随机重置的取值上界）
%
% 处理流程：
%   对每个个体以 mutation_probability 概率触发变异：
%   1. 随机生成两个位置索引 start_point、end_point
%   2. 若 start_point ≤ end_point：对 [start_point, end_point] 区间随机重置
%   3. 若 start_point > end_point：视为环形区间，分别对
%      [start_point, subtask_num] 和 [1, end_point] 两段随机重置
%
% 输出：
%   Population_mutated - 变异后的种群矩阵 [population_size × subtask_num]
function [Population_mutated] = mutate(Population,mutation_probability,candidate_service_num)
Population_mutated = Population;
[population_size,subtask_num] = size(Population);
for i = 1:population_size
    if rand <= mutation_probability
        Section = randi(subtask_num,1,2); % 产生变异区间
        start_point = Section(1,1);
        end_point = Section(1,2);
        if start_point <= end_point
            Section_temp = randi(candidate_service_num,1,end_point-start_point+1);
            Population_mutated(i,start_point:end_point) = Section_temp;
        else
            Section_temp_back = randi(candidate_service_num,1,subtask_num-start_point+1);
            Population_mutated(i,start_point:subtask_num) = Section_temp_back;
            Section_temp_front = randi(candidate_service_num,1,end_point);
            Population_mutated(i,1:end_point) = Section_temp_front;
        end
    end
end
end

