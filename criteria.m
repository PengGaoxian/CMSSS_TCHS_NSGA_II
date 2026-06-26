% 功能：计算种群中每个个体完成所有子任务所需的服务质量、服务成本与完成时间。
%
% 输入：
%   Population              — [population_size × subtask_num] 种群矩阵，每个元素为候选服务索引
%   Q                       — [candidate_service_num × subtask_num] 候选服务质量矩阵
%   Cs                      — [candidate_service_num × subtask_num] 候选服务成本矩阵
%   End_candidate_service   — [population_size × subtask_num] 各个体各子任务的服务结束时间
%   Cl                      — [population_size × subtask_num] 各个体各段物流成本
%
% 处理流程：
%   1. 遍历种群中每个个体，累加其所选候选服务的质量之和与服务成本之和
%   2. 累加物流成本 Cl，得到总成本 = 服务成本 + 物流成本
%   3. 以最后一个子任务的服务结束时间作为整体完成时间
%   4. 质量取各子任务的平均值（归一化到 [0,1]）
%
% 输出：
%   Quality — [population_size × 1] 各个体的平均服务质量（越大越好）
%   Cost    — [population_size × 1] 各个体的总成本（服务成本 + 物流成本，越小越好）
%   Time    — [population_size × 1] 各个体的任务完成时间（越小越好）
function [Quality,Cost,Time] = criteria(Population,Q,Cs,End_candidate_service,Cl)
[population_size,subtask_num] = size(Population);

total_Q = zeros(population_size,1);
total_Cs = zeros(population_size,1);
total_Cl = zeros(population_size,1);
total_T = zeros(population_size,1);
for k = 1:population_size
    for i = 1:subtask_num
        candidate_service_index = Population(k,i);
        total_Q(k,1) = total_Q(k,1) + Q(candidate_service_index,i);
        total_Cs(k,1) = total_Cs(k,1) + Cs(candidate_service_index,i);
    end
    total_Cl(k,1) = sum(Cl(k,:));
    total_T(k,1) = End_candidate_service(k,end);
end

Quality = total_Q/subtask_num;
Cost = total_Cs + total_Cl;
Time = total_T;
end