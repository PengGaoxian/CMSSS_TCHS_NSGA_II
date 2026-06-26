% 功能：根据种群个体的服务选择方案，从预计算的距离矩阵中查表，
%       计算每个个体各子任务间的物流时间矩阵 Tl 和物流成本矩阵 Cl。
%
% 输入：
%   Population    - 种群矩阵 [population_size × subtask_num]，
%                   每个元素为对应子任务所选候选服务的序号（1-indexed）
%   Distance_cell - 物流距离 cell [candidate_service_num × subtask_num]，
%                   由 global_parameters_block 预计算，
%                   Distance_cell{j,i} 为子任务 i 的第 j 个候选服务
%                   到子任务 i+1 所有候选服务的距离列向量
%   T_unit_dist   - 单位距离物流时间系数
%   C_unit_dist   - 单位距离物流成本系数
%
% 处理流程：
%   1. 对每个个体 k、每个相邻子任务对 (i, i+1)，
%      从 Distance_cell{当前服务序号, i} 中查取到下一服务的距离，
%      填入距离矩阵 Dist [population_size × subtask_num]
%   2. Tl = Dist * T_unit_dist（逐元素乘）
%   3. Cl = Dist * C_unit_dist（逐元素乘）
%
% 输出：
%   Tl - 物流时间矩阵 [population_size × subtask_num]，
%        每行对应一个个体，每列对应一个子任务间的物流时间
%   Cl - 物流成本矩阵 [population_size × subtask_num]，结构同 Tl
function [Tl,Cl] = logistics(Population,Distance_cell,T_unit_dist,C_unit_dist)
[population_size,subtask_num] = size(Population);
Dist = zeros(population_size,subtask_num);
for k = 1:population_size
    for i = 1:subtask_num-1
        current_candidate_service = Population(k,i); % 同一个体中前一个候选服务的序号
        next_candidate_service = Population(k,i+1); % 同一个体中后一个候选服务的序号
        A = Distance_cell{current_candidate_service,i}; %  
        Dist(k,i) = A(next_candidate_service,1);
    end
end
Tl = Dist*T_unit_dist;
Cl = Dist*C_unit_dist;
end

