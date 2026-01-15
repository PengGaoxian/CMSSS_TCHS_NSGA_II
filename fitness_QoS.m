%% 适应度函数
% 输入
%   Population：种群
%   Q：候选服务的服务质量数据集
%   Cs：候选服务的服务成本数据集
%   Ts：候选服务的服务时长数据集
%   Idle：候选服务的空闲时间数据集
%   Time_required_max：客户要求的最迟完成时间（deadline）
%   w_Quality：完成任务的质量权重
%   w_Cost：完成任务的成本权重
%   w_Time：完成任务的时间权重
% 输出
%   Fitness：种群的适应度
%   Fitness_sort：经过降序排列后的种群适应度
%   Fitness_sort_index：经过降序排列后的原始序号
function [Fitness] = fitness_QoS(Quality_dimensionless,Cost_dimensionless,Time_dimensionless,w_Quality,w_Cost,w_Time)
% 计算适应度
[population_size,~] = size(Quality_dimensionless);
Fitness = ones(population_size,1);
for k = 1:population_size
    if Quality_dimensionless(k,1)>1 || Cost_dimensionless(k,1)>1 || Time_dimensionless(k,1)>1
        Fitness(k,1) = Inf;
    else
        Fitness(k,1) = w_Quality*Quality_dimensionless(k,1) + w_Cost*Cost_dimensionless(k,1) + w_Time*Time_dimensionless(k,1);
    end
end

