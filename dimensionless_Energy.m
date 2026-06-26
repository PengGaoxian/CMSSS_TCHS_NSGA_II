% 功能：对种群中每个个体的预热能耗进行无量纲化处理，映射到 [0, 1] 区间，
%       使能耗与 QoS 具有相同量纲，便于适应度计算与 Pareto 比较。
%
% 输入：
%   Energy     - 候选服务的实际预热能耗（标量或向量）
%   Energy_max - 候选服务预热能耗的最大值（归一化基准）
%
% 处理流程：
%   Energy_dimensionless = Energy / Energy_max
%   （逐元素相除，结果落在 [0, 1] 区间）
%
% 输出：
%   Energy_dimensionless - 归一化后的能耗值，供 fitness_Energy 使用
function [Energy_dimensionless] = dimensionless_Energy(Energy,Energy_max)
Energy_dimensionless = Energy/Energy_max;
end

