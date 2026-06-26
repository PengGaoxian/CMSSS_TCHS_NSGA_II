% 功能：计算候选服务在某空闲时段内的任务衔接度（Task Cohesion），
%       衡量服务执行窗口与空闲时段边界的紧密程度，用于估算实际预热能耗。
%       衔接度越高，说明服务与相邻已有任务衔接越紧密，所需额外预热能耗越少。
%
% 输入：
%   Th_candidate_service - 候选服务的预热时长
%   Tc_candidate_service - 候选服务的冷却时长
%   Periods              - 候选服务所在空闲时段的边界向量（奇数索引=空闲开始，偶数索引=空闲结束）
%   start_time           - 服务执行开始时间
%   end_time             - 服务执行结束时间
%
% 处理流程：
%   1. 定位空闲时段：找到 start_time 左侧最近的空闲段起点 idle_start，
%      以及 end_time 右侧最近的空闲段终点 idle_end
%   2. 计算前向衔接度 cohesion_prev：
%      若 (start_time - idle_start) >= (Th + Tc)，则 cohesion_prev = 0（间距足够，无衔接）；
%      否则 cohesion_prev = 1 - (start_time - idle_start) / (Th + Tc)
%   3. 计算后向衔接度 cohesion_next：
%      若 (idle_end - end_time) >= (Th + Tc)，则 cohesion_next = 0；
%      否则 cohesion_next = 1 - (idle_end - end_time) / (Th + Tc)
%   4. 总衔接度 cohesion = cohesion_prev + cohesion_next，理论范围 [0, 2]

%
% 输出：
%   cohesion - 总衔接度，供 preheating_energy 计算实际预热能耗使用：
%              实际预热能耗 = Eh * (2 - cohesion)，cohesion 越大能耗越低
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

