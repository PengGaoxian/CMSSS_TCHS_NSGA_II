% 功能：计算下层适应度（Demander 侧 QoS 目标），作为双层优化的下层目标函数。
%       对不可行个体（任一 QoS 指标超出用户约束）赋予 Inf 惩罚。
%
% 输入：
%   Quality_dimensionless - 归一化质量值 [population_size × 1]，由 dimensionless_QoS 计算
%   Cost_dimensionless    - 归一化费用值 [population_size × 1]，由 dimensionless_QoS 计算
%   Time_dimensionless    - 归一化时间值 [population_size × 1]，由 dimensionless_QoS 计算
%   w_Quality             - 质量权重
%   w_Cost                - 费用权重
%   w_Time                - 时间权重
%
% 处理流程：
%   逐个体判断可行性：若 Quality / Cost / Time 任一归一化值 > 1（违反用户约束），
%   则适应度设为 Inf（不可行解）；否则按加权求和计算：
%   Fitness = w_Quality * Quality_dimensionless + w_Cost * Cost_dimensionless + w_Time * Time_dimensionless
%
% 输出：
%   Fitness - 下层适应度列向量 [population_size × 1]，
%             值越小表示 QoS 综合表现越好，Inf 表示不可行解
function [Fitness] = fitness_QoS(Quality_dimensionless,Cost_dimensionless,Time_dimensionless,w_Quality,w_Cost,w_Time)
[population_size,~] = size(Quality_dimensionless);
Fitness = ones(population_size,1);
for k = 1:population_size
    if Quality_dimensionless(k,1)>1 || Cost_dimensionless(k,1)>1 || Time_dimensionless(k,1)>1
        Fitness(k,1) = Inf;
    else
        Fitness(k,1) = w_Quality*Quality_dimensionless(k,1) + w_Cost*Cost_dimensionless(k,1) + w_Time*Time_dimensionless(k,1);
    end
end

