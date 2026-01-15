%% 通过空闲时间段Idle计算占用时间段Occupancy
% 输入
%   Idle：空闲时间段
%   Time_elasticity：0~deadline扩展后的时间段
% 输出
%   Occupancy：占用时间段
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

