%% 子任务对应的候选服务的实际预热能耗
% 输入
%   Eh：候选服务的预热能耗
%   Population：种群
%   Th：预热时间
%   Tc：冷却时间
%   Idle：空闲时间
%   Start_candidate_service：候选服务的服务开始时间
%   End_candidate_service：候选服务的服务结束时间
% 输出
%   E：种群中个体的实际预热能耗
function [E] = preheating_energy(Eh,Population,Th,Tc,Idle,Start_candidate_service,End_candidate_service)
[population_size,subtask_num] = size(Population);
E = zeros(population_size,subtask_num);
for k = 1:population_size
    for i = 1:subtask_num
        candidate_service = Population(k,i); % 候选服务
        Periods = Idle{candidate_service,i}; % 候选服务的空闲时段
        start_time = Start_candidate_service(k,i); % 第k个个体的第i个子任务对应的服务开始时间
        end_time = End_candidate_service(k,i); % 第k个个体的第i个子任务对应的服务的结束时间
        Th_candidate_service = Th(candidate_service,i); % 候选服务预热时长
        Tc_candidate_service = Tc(candidate_service,i); % 候选服务冷却时长
        
        cohesion = get_cohesion(Th_candidate_service,Tc_candidate_service,Periods,start_time,end_time); % 获取任务衔接度
        
        energy = Eh(candidate_service,i); % 候选服务启动能耗
        E(k,i) = energy * (2 - cohesion); % cohesion包括前向衔接度和后向衔接度，最大值为2
    end
end
