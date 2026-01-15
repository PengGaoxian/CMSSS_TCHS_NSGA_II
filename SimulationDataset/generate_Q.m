%% 生成candidate_service_num行、subtask_num列候选服务的质量数据集
% 输入
%   subtask_num：子任务的数量
%   candidate_service_num：每个子任务对应的候选服务的数量
%   Avg_qos：子任务对应的候选服务的质量数据的均值
%   Std_qos：子任务对应的候选服务的质量数据的标准差
% 输出
%   Q：候选服务的质量数据集
function [Q] = generate_Q(subtask_num,candidate_service_num,Avg_qos,Std_qos)
Q = zeros(candidate_service_num,subtask_num); % 服务质量矩阵
for i = 1:subtask_num 
    % 生成均值为qos_avg_on_mcs，标准差为qos_std_on_mcs的正态分布的MCS_i集合数据
    Q(:,i) = normrnd(Avg_qos(1,i), Std_qos(1,i), candidate_service_num, 1);
end
disp(Q);
end

