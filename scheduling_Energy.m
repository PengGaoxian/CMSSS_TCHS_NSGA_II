% 功能：为种群中每个个体计算各子任务的服务开始/结束时间（EOS 策略）。
%       从前向后顺序遍历子任务，在 MOS 调度基础上，
%       将子任务服务窗口向空闲时段右端移动（最大化后向衔接度），以降低预热能耗。
%       与 MEOS 不同，EOS 不保证 makespan 不变，以能耗优化为优先目标。
%
% 输入：
%   Population         - 种群矩阵 [population_size × subtask_num]，元素为候选服务序号
%   Th                 - 预热时长矩阵 [candidate_service_num × subtask_num]
%   Tc                 - 冷却时长矩阵 [candidate_service_num × subtask_num]
%   Ds                 - 服务时长矩阵 [candidate_service_num × subtask_num]
%   Idle               - 空闲时段 cell [candidate_service_num × subtask_num]
%   ordertime          - 任务下单时刻（调度起始时间）
%   Time_required_max  - 用户要求的最大完成时间（deadline = ordertime + Time_required_max）
%   Dl                 - 物流时长矩阵 [population_size × subtask_num]，由 logistics 计算
%
% 处理流程：
%   对每个个体 k，从第 1 个子任务到第 subtask_num 个子任务顺序处理：
%   【MOS 调度】找到满足空闲约束的最早可用时间窗口（与 scheduling_Makespan.m 相同逻辑）
%   【EOS 优化】计算衔接度 cohesion，若 cohesion < 1 且任务未超出 deadline：
%     将结束时间移至当前空闲时段右端（t_ir^k），start_time = end_time - service_duration
%   下一子任务 start_time = 当前 end_time + 物流时长
%
% 输出：
%   Start_candidate_service - 服务执行开始时间矩阵 [population_size × subtask_num]
%   End_candidate_service   - 服务执行结束时间矩阵 [population_size × subtask_num]
function [Start_candidate_service,End_candidate_service] = scheduling_Energy(Population,Th,Tc,Ds,Idle,ordertime,Time_required_max,Dl)
[population_size,subtask_num] = size(Population);
Start_candidate_service = zeros(population_size,subtask_num);
End_candidate_service = zeros(population_size,subtask_num);
deadline = ordertime + Time_required_max;
for k = 1:population_size
    start_time = ordertime;
    for i = 1:subtask_num
        candidate_service_index = Population(k,i);
        Periods = Idle{candidate_service_index,i};
        service_duration = Ds(candidate_service_index,i);
        logistics_duration = Dl(k,i);
        Th_candidate_service = Th(candidate_service_index,i);
        Tc_candidate_service = Tc(candidate_service_index,i);

        %% MOS调度：找到满足空闲约束的最早可用时间窗口
        while true
            end_time = start_time + service_duration;
            start_time_next_index = find(Periods>start_time, 1, 'first');
            end_time_prev_index = find(Periods<end_time, 1, 'last');

            if end_time > deadline % 超出deadline，标记为不可行解
                break;
            elseif isempty(start_time_next_index) % start_time已超出所有空闲时段
                break;
            elseif mod(start_time_next_index,2)==1 % start_time处于占用时间段
                start_time = Periods(start_time_next_index);
            elseif mod(start_time_next_index,2) == 0 % start_time处于空闲时间段
                if start_time_next_index ~= end_time_prev_index+1 % end_time跨越了当前空闲时段
                    if start_time_next_index+1 > numel(Periods)
                        break;
                    end
                    start_time = Periods(start_time_next_index+1);
                else % start_time与end_time在同一空闲时段内
                    break;
                end
            end
        end

        %% EOS优化：将服务窗口向空闲时段右端移动，最大化后向衔接度
        % end_time_prev_index < numel(Periods) 排除超出deadline的不可行解
        cohesion = get_cohesion(Th_candidate_service,Tc_candidate_service,Periods,start_time,end_time);
        if end_time_prev_index < numel(Periods) && cohesion < 1
            end_time = Periods(start_time_next_index); % 移至空闲时段右端（t_ir^k）
            start_time = end_time - service_duration;
        end

        Start_candidate_service(k,i) = start_time;
        End_candidate_service(k,i) = end_time;
        start_time = end_time + logistics_duration; % 下一子任务到达时间 = 当前结束时间 + 物流时长
    end
end
end
