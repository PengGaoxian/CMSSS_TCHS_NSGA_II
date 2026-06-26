% 功能：为种群中每个个体计算各子任务的服务开始/结束时间（FSGS 策略）。
%       纯正向调度：以最早可用时间为准，将每个子任务分配到满足空闲约束的最早时间窗口，
%       不做反向遍历优化，与 scheduling_Makespan_Energy 形成对照。
%
% 输入：
%   Population         - 种群矩阵 [population_size × subtask_num]，元素为候选服务序号
%   Ts                 - 服务时长矩阵 [candidate_service_num × subtask_num]
%   Idle               - 空闲时段 cell [candidate_service_num × subtask_num]
%   ordertime          - 任务下单时刻（调度起始时间）
%   Time_required_max  - 用户要求的最大完成时间（deadline = ordertime + Time_required_max）
%   Tl                 - 物流时长矩阵 [population_size × subtask_num]，由 logistics 计算
%
% 处理流程：
%   对每个个体 k，从 ordertime 出发正向遍历每个子任务 i：
%   在 while 循环中反复检查当前 [start_time, end_time] 是否满足空闲约束：
%   - 若 end_time 超出 deadline：直接记录（标记为不可行解），退出循环
%   - 若 start_time 落在占用段内（start_time_next_index 为奇数）：
%     推移 start_time 至该占用段结束时刻
%   - 若 start_time 在空闲段内（start_time_next_index 为偶数）：
%     · 若 end_time 与 start_time 不在同一空闲段：推移至下一占用段结束后重试
%     · 若二者在同一空闲段：记录合法时间窗口，退出循环
%   下一子任务 start_time = 当前 end_time + 物流时长 Tl(k,i)
%
% 输出：
%   Start_candidate_service - 服务执行开始时间矩阵 [population_size × subtask_num]
%   End_candidate_service   - 服务执行结束时间矩阵 [population_size × subtask_num]
function [Start_candidate_service,End_candidate_service] = scheduling_Makespan(Population,Ts,Idle,ordertime,Time_required_max,Tl)
[population_size,subtask_num] = size(Population);
Start_candidate_service = zeros(population_size,subtask_num); % 定义cs_ji的开始时间矩阵
End_candidate_service = zeros(population_size,subtask_num); % 定义cs_ji的结束时间矩阵
deadline = ordertime + Time_required_max;
for k = 1:population_size
    %% 计算完成任务的结束时间
    start_time = ordertime; % 候选服务的服务开始时间
    for i = 1:subtask_num
        candidate_service = Population(k,i); % 子任务对应的候选云服务的序号ji
        Periods = Idle{candidate_service,i}; % 空闲时间段矩阵
        duration = Ts(candidate_service,i); % 候选服务的服务持续时间
       %% 子任务调度
        while true
            end_time = start_time + duration; % 候选服务的服务结束时间
            start_time_next_index = find(Periods>start_time, 1, 'first');
            end_time_prev_index = find(Periods<end_time, 1, 'last');
            if end_time > deadline % 服务结束时间超出deadline
                Start_candidate_service(k,i) = start_time;
                End_candidate_service(k,i) = end_time;
                break;
            elseif isempty(start_time_next_index) % start_time已超出所有空闲时段，无可用窗口
                Start_candidate_service(k,i) = start_time;
                End_candidate_service(k,i) = end_time;
                break;
            elseif mod(start_time_next_index,2)==1 % start_time处于占用时间段
                start_time = Periods(start_time_next_index);
            elseif mod(start_time_next_index,2) == 0 % start_time处于空闲时间段
                if start_time_next_index ~= end_time_prev_index+1 % end_time与start_time不在同一空闲时间段
                    if start_time_next_index+1 > numel(Periods) % 已是最后一个空闲时段，无后续窗口
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
        start_time = end_time+Tl(k,i); % 将下一个候选云服务的开始时间=当前云服务的结束时间+物流时间
    end
end
end