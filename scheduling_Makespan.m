%% 计算种群中每个个体完成任务的总时间
% 输入
%   Population：种群
%   Ts：候选服务时长数据集
%   Idle：候选服务空闲时间数据集
%   ordertime：任务下单时刻
%   Tl：物流时长
% 输出
%   Start_candidate_service：候选服务执行相应子任务的时刻
%   End_candidate_service：候选服务完成相应子任务的时刻
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
            elseif mod(start_time_next_index,2)==1 % start_time处于占用时间段
                start_time = Periods(start_time_next_index);
            elseif mod(start_time_next_index,2) == 0 % start_time处于空闲时间段
                if start_time_next_index ~= end_time_prev_index+1 % end_time与start_time不在同一空闲时间段
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