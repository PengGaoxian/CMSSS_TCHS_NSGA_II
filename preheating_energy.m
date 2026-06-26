% 功能：计算种群中每个个体各子任务所选候选服务的实际预热能耗矩阵。
%       通过任务衔接度（get_cohesion）将满载预热能耗 Eh 折算为实际消耗：
%       衔接度越高，服务与相邻任务的时间间隙越小，实际预热能耗越低。
%
% 输入：
%   Eh                        - 满载预热能耗矩阵 [candidate_service_num × subtask_num]
%   Population                - 种群矩阵 [population_size × subtask_num]，元素为候选服务序号
%   Th                        - 预热时长矩阵 [candidate_service_num × subtask_num]
%   Tc                        - 冷却时长矩阵 [candidate_service_num × subtask_num]
%   Idle                      - 空闲时段 cell [candidate_service_num × subtask_num]
%   Start_candidate_service   - 服务执行开始时间矩阵 [population_size × subtask_num]
%   End_candidate_service     - 服务执行结束时间矩阵 [population_size × subtask_num]
%
% 处理流程：
%   对每个个体 k、每个子任务 i：
%   1. 取出所选候选服务序号、对应空闲时段 Idle、服务开始/结束时间
%   2. 调用 get_cohesion 计算任务衔接度 cohesion（范围 [0, 2]）
%   3. 实际预热能耗 = Eh(候选服务, i) × (2 - cohesion)
%      cohesion = 2 时能耗为 0（完全衔接），cohesion = 0 时能耗为 2×Eh（满载）
%
% 输出：
%   E - 实际预热能耗矩阵 [population_size × subtask_num]，
%       按行求和（sum(E,2)）即为每个个体的总预热能耗，供 dimensionless_Energy 使用
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
        E(k,i) = energy * (2 - cohesion); % 实际预热能耗，cohesion=0时为2×Eh（冷启动），cohesion=2时为0（完全衔接）
    end
end
