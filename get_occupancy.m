% 功能：由候选服务的空闲时段 Idle 推导出对应的占用时段 Occupancy，
%       即将 [0, Time_elasticity] 区间内空闲时段的补集转换为占用时段。
%
% 输入：
%   Idle            - 空闲时段 cell [candidate_service_num × subtask_num]，
%                     每元素为 2×n 矩阵（第1行=空闲开始时间，第2行=空闲结束时间）
%   Time_elasticity - 时间轴上界（通常为 deadline 扩展后的值）
%
% 处理流程：
%   对每个候选服务逐一处理：
%   1. 以 Idle 的结束时间为占用开始，在最前补 0；
%      以 Idle 的开始时间为占用结束，在最后补 Time_elasticity，
%      拼合为 2×m 的 Occupancy_combine（第1行=占用开始，第2行=占用结束）
%   2. 若首列的占用开始与结束相同（即 0 时刻恰好是空闲起点），删除该列（零宽占用）
%   3. 若末列的占用开始与结束相同（即 Time_elasticity 恰好是空闲终点），删除该列
%   4. 将处理结果存入对应的 Occupancy cell 元素
%
% 输出：
%   Occupancy - 占用时段 cell [candidate_service_num × subtask_num]，
%               每元素为 2×m 矩阵（第1行=占用开始，第2行=占用结束），
%               供调度函数判断候选服务的可用窗口使用
function [Occupancy] = get_occupancy(Idle,Time_elasticity)
[candidate_service_num,subtask_num] = size(Idle);
Occupancy = cell(candidate_service_num,subtask_num);
for i = 1:subtask_num
    for j = 1:candidate_service_num
        Periods = Idle{j,i};
        Occupancy_start = [0,Periods(2,:)];
        Occupancy_end = [Periods(1,:),Time_elasticity];
        Occupancy_combine = [Occupancy_start;Occupancy_end];
        if Occupancy_combine(1,1) == Occupancy_combine(2,1)
            Occupancy_combine(:,1) = [];
        end
        if Occupancy_combine(1,end) == Occupancy_combine(2,end)
            Occupancy_combine(:,end) = [];
        end
        Occupancy{j,i} = Occupancy_combine;
    end
end
end

