% 功能：为种群中每个个体计算各子任务的服务开始/结束时间（ESGS 策略）。
%       第一阶段正向调度确定 makespan，第二阶段从后向前反向遍历，
%       在不延误后续子任务的前提下将服务窗口向衔接度更高的位置移动，以降低预热能耗。
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
%   对每个个体 k：
%   【第一阶段：正向调度确定 makespan】
%     从 ordertime 出发，依次为每个子任务 i 找到满足空闲约束的最早可用时间窗口：
%     - 若 start_time 落在占用段内，推移至该占用段结束；
%     - 若执行区间跨越多个空闲段，推移至下一占用段结束后重试；
%     - 若超出 deadline，直接记录（标记为不可行解）；
%     下一子任务 start_time = 当前结束时间 + 物流时长
%   【第二阶段：反向遍历优化能耗（从第 subtask_num-1 到第 1 个子任务）】
%     计算当前窗口的衔接度 cohesion；若 cohesion < 1 表示有优化空间：
%     - 若空闲段右端 + 物流时长 ≤ 下一子任务开始时间：
%       将结束时间贴近空闲段右端（最大化后向衔接），更新 start_time
%     - 否则：将结束时间设为 下一子任务开始时间 - 物流时长，
%       计算新衔接度，仅当新衔接度更高时才接受调整
%
% 输出：
%   Start_candidate_service - 服务执行开始时间矩阵 [population_size × subtask_num]
%   End_candidate_service   - 服务执行结束时间矩阵 [population_size × subtask_num]
function [Start_candidate_service,End_candidate_service] = scheduling_Makespan_Energy(Population,Th,Tc,Ds,Idle,ordertime,Time_required_max,Dl)
[population_size,subtask_num] = size(Population);
Start_candidate_service = zeros(population_size,subtask_num); % 定义cs_ji的开始时间矩阵
End_candidate_service = zeros(population_size,subtask_num); % 定义cs_ji的结束时间矩阵
deadline = ordertime + Time_required_max;
for k = 1:population_size
    %% 计算完成任务的结束时间
    start_time = ordertime; % 候选服务的服务开始时间
    for i = 1:subtask_num
        candidate_service_index = Population(k,i); % 子任务对应的候选云服务的序号ji
        Periods = Idle{candidate_service_index,i}; % 空闲时间段矩阵
        service_duration = Ds(candidate_service_index,i); % 候选服务的服务持续时间
        logistics_duration = Dl(k,i);
        
       %% 子任务调度
        while true
            end_time = start_time + service_duration; % 候选服务的服务结束时间
            start_time_next_index = find(Periods>start_time, 1, 'first');
            end_time_prev_index = find(Periods<end_time, 1, 'last');
            
            if end_time > deadline % 服务结束时间超出deadline
                Start_candidate_service(k,i) = start_time;
                End_candidate_service(k,i) = end_time;
                break;
            elseif isempty(start_time_next_index) % start_time已超出所有空闲时段
                Start_candidate_service(k,i) = start_time;
                End_candidate_service(k,i) = end_time;
                break;
            elseif mod(start_time_next_index,2)==1 % start_time处于占用时间段
                start_time = Periods(start_time_next_index);
            elseif mod(start_time_next_index,2) == 0 % start_time处于空闲时间段
                if start_time_next_index ~= end_time_prev_index+1 % end_time与start_time不在同一空闲时间段
                    if start_time_next_index+1 > numel(Periods)
                        Start_candidate_service(k,i) = start_time;
                        End_candidate_service(k,i) = end_time;
                        break;
                    end
                    start_time = Periods(start_time_next_index+1);
                elseif start_time_next_index == end_time_prev_index+1 % end_time与start_time在同一空闲时间段
                    Start_candidate_service(k,i) = start_time;
                    End_candidate_service(k,i) = end_time;           
                    break;
                end
            end
        end
        start_time = end_time + logistics_duration; % 将下一个候选云服务的开始时间=当前云服务的结束时间+物流时间
    end
    %% 保证时间不变的前提下优化能耗
%     for i = 1:subtask_num-1
%         candidate_service_index = Population(k,i); % 子任务对应的候选云服务的序号ji
%         Th_candidate_service = Th(candidate_service_index,i); % 候选服务的预热时长
%         Tc_candidate_service = Tc(candidate_service_index,i); % 候选服务的冷却时长
%         Periods = Idle{candidate_service_index,i}; % 空闲时间段矩阵
%         service_duration = Ds(candidate_service_index,i); % 候选服务的服务持续时间
%         logistics_duration = Dl(k,i);
%         start_time = Start_candidate_service(k,i);
%         end_time = End_candidate_service(k,i);
% 
%         start_time_next_subtask = Start_candidate_service(k,i+1);
% 
%         start_time_next_index = find(Periods>start_time, 1, 'first');
%         
%         cohesion = get_cohesion(Th_candidate_service,Tc_candidate_service,Periods,start_time,end_time); % 获取子任务的衔接度
%         if cohesion < 1 % 如果衔接度小于1，则有进一步优化空间
%             if Periods(start_time_next_index)+logistics_duration <= start_time_next_subtask % 如果空闲时段的结束时间+物流时间，小于下一个子任务的开始时间
%                 end_time = Periods(start_time_next_index); % 当前子任务的结束时间设置为空闲时间的结束时间
%                 start_time = end_time-service_duration;
%             else % 如果空闲时段的结束时间+物流时间，大于下一个子任务的开始时间
%                 end_time_new = start_time_next_subtask-logistics_duration; % 当前子任务的结束时间设置为下一个子任务的开始时间-物流时间
%                 start_time_new = end_time_new-service_duration; 
%                 cohesion_new = get_cohesion(Th_candidate_service,Tc_candidate_service,Periods,start_time_new,end_time_new);
%                 if cohesion < cohesion_new % 如果调度后的衔接度大于调度前的衔接度，则修改子任务执行时间
%                     start_time = start_time_new;
%                     end_time = end_time_new;
%                 end
%             end
%         end
%         Start_candidate_service(k,i) = start_time;
%         End_candidate_service(k,i) = end_time;
%     end
    for i = subtask_num-1:-1:1
        candidate_service_index = Population(k,i); % 子任务对应的候选云服务的序号ji
        Th_candidate_service = Th(candidate_service_index,i); % 候选服务的预热时长
        Tc_candidate_service = Tc(candidate_service_index,i); % 候选服务的冷却时长
        Periods = Idle{candidate_service_index,i}; % 空闲时间段矩阵
        service_duration = Ds(candidate_service_index,i); % 候选服务的服务持续时间
        logistics_duration = Dl(k,i);
        start_time = Start_candidate_service(k,i);
        end_time = End_candidate_service(k,i);

        start_time_next_subtask = Start_candidate_service(k,i+1);

        start_time_next_index = find(Periods>start_time, 1, 'first');
        
        cohesion = get_cohesion(Th_candidate_service,Tc_candidate_service,Periods,start_time,end_time); % 获取子任务的衔接度
        if cohesion < 1 % 如果衔接度小于1，则有进一步优化空间
            if Periods(start_time_next_index)+logistics_duration <= start_time_next_subtask % 如果空闲时段的结束时间+物流时间，小于下一个子任务的开始时间
                end_time = Periods(start_time_next_index); % 当前子任务的结束时间设置为空闲时间的结束时间
                start_time = end_time-service_duration;
            else % 如果空闲时段的结束时间+物流时间，大于下一个子任务的开始时间
                end_time_new = start_time_next_subtask-logistics_duration; % 当前子任务的结束时间设置为下一个子任务的开始时间-物流时间
                start_time_new = end_time_new-service_duration; 
                cohesion_new = get_cohesion(Th_candidate_service,Tc_candidate_service,Periods,start_time_new,end_time_new);
                if cohesion < cohesion_new % 如果调度后的衔接度大于调度前的衔接度，则修改子任务执行时间
                    start_time = start_time_new;
                    end_time = end_time_new;
                end
            end
        end
        Start_candidate_service(k,i) = start_time;
        End_candidate_service(k,i) = end_time;
    end
end
end