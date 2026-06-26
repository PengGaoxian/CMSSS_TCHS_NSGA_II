% 功能：对 QoS 三个指标（质量、成本、时间）进行无量纲化处理，映射到 [0, 1] 区间，
%       值越小表示个体表现越好，供适应度计算与 Pareto 比较使用。
%
% 输入：
%   Quality              - 完成任务所获得的质量
%   Cost                 - 完成任务所需的总费用
%   Time                 - 完成任务所需的总时间（makespan）
%   Time_required_max    - 用户要求的最晚交付时间（deadline）
%   Cost_required_max    - 用户设定的总任务费用预算
%   Quality_required_min - 用户要求的最低任务质量
%   Time_min             - 种群中时间的最小值（归一化下界）
%   Cost_min             - 种群中费用的最小值（归一化下界）
%   Quality_max          - 种群中质量的最大值（归一化上界）
%
% 处理流程：
%   Quality_dimensionless = (Quality_max - Quality) / (Quality_max - Quality_required_min)
%     质量越高越好，取反方向归一化；超过 1 表示不满足用户最低质量要求
%   Time_dimensionless    = (Time - Time_min) / (Time_required_max - Time_min)
%     时间越短越好，正向归一化；超过 1 表示超出 deadline
%   Cost_dimensionless    = (Cost - Cost_min) / (Cost_required_max - Cost_min)
%     费用越少越好，正向归一化；超过 1 表示超出预算
%
% 输出：
%   Quality_dimensionless - 归一化质量（值越小越好）
%   Cost_dimensionless    - 归一化费用（值越小越好）
%   Time_dimensionless    - 归一化时间（值越小越好）
function [Quality_dimensionless,Cost_dimensionless,Time_dimensionless] = dimensionless_QoS(Quality,Cost,Time,Time_required_max,Cost_required_max,Quality_required_min,Time_min,Cost_min,Quality_max)
Quality_dimensionless = (Quality_max - Quality)/(Quality_max - Quality_required_min);
Time_dimensionless = (Time-Time_min)/(Time_required_max-Time_min);
Cost_dimensionless = (Cost-Cost_min)/(Cost_required_max-Cost_min);