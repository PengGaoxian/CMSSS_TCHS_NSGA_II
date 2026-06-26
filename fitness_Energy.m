% 功能：计算上层适应度（Provider 侧能耗目标），作为双层优化的上层目标函数。
%
% 输入：
%   Energy_dimensionless - 归一化后的预热能耗值，由 dimensionless_Energy 计算得到，
%                          范围 [0, 1]，值越小表示能耗越低
%
% 处理流程：
%   直接将归一化能耗作为上层适应度返回（当前为直通映射，
%   保留函数封装以便后续扩展加权或惩罚项）
%
% 输出：
%   Fitness_top - 上层适应度值，供 Pareto 选择与种群评估使用
function [Fitness_top] = fitness_Energy(Energy_dimensionless)
Fitness_top = Energy_dimensionless;
end

