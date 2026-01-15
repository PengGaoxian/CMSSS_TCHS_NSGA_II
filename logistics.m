%% 通过种群个体和位置矩阵计算物流时间和物流成本
% 输入
%   Population：种群
%   P：候选服务的位置
% 输出
%   Tl：物流时间
%   Cl：物流成本
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

