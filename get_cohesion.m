%% 计算子任务的衔接度
% 输入
%   Th_candidate_service：候选服务的预热时长
%   Tc_candidate_service：候选服务的冷却时长
%   Periods：候选服务的空闲时间
%   start_time：服务开始时间
%   end_time：服务结束时间
% 输出
%   cohesion：子任务衔接度
function [cohesion] = get_cohesion(Th_candidate_service,Tc_candidate_service,Periods,start_time,end_time)
preheating_time = Th_candidate_service; % 候选服务预热时长
cooling_time = Tc_candidate_service; % 候选服务冷却时长
idle_start_index = find(Periods<=start_time,1,'last'); % 找到服务开始时间左侧的空闲开始时间的序号
idle_end_index = find(Periods>=end_time,1,'first'); % 找到服务ujieshu时间的右侧的空闲结束时间的序号
idle_start = Periods(idle_start_index); % 候选服务开始时间左侧的空闲开始时间
idle_end = Periods(idle_end_index); % 候选服务结束时间右侧的空闲结束时间

cohesion_prev = 0;
cohesion_next = 0;
%% 前向衔接度计算
if (start_time-idle_start)/(preheating_time+cooling_time) >= 1
    cohesion_prev = 0;
elseif(start_time-idle_start)/(preheating_time+cooling_time) < 1
    cohesion_prev = 1 - (start_time-idle_start)/(preheating_time+cooling_time);
else
    disp([mfilename,': exception of Start_candidate_service']);
end
%% 后向衔接度计算
if (idle_end-end_time)/(preheating_time+cooling_time) >= 1
    cohesion_next = 0;
elseif (idle_end-end_time)/(preheating_time+cooling_time) < 1
    cohesion_next = 1 - (idle_end-end_time)/(preheating_time+cooling_time);
else
    disp([mfilename,': task scheduling beyond deadline']);
end
cohesion = cohesion_prev + cohesion_next;
end

