%% 生成候选服务的服务时长数据集（服务时长与性价比正相关）
% 输入
%   Q：候选服务质量数据集
%   Cs：候选服务成本数据集
%   Avg_Ts：子任务对应的候选服务的服务时长均值
%   Std_Ts：子任务对应的候选服务的服务时长标准差
% 输出
%   Ts：候选服务的服务时长数据集
function [Ts] = generate_Ts(Q,Cs,Avg_Ts,Std_Ts)
[candidate_service_num,subtask_num] = size(Q);
Ts = zeros(candidate_service_num,subtask_num); % 服务时长矩阵
for i = 1:subtask_num 
    % 生成均值为Tm_avg_on_mcs，标准差为Tm_std_on_mcs的正态分布的MCS_i集合数据
    tmp(:,1) = normrnd(Avg_Ts(1,i), Std_Ts(1,i), candidate_service_num, 1);
    [~,order1] = sort(Q(:,i)./Cs(:,i)); % 性价比排序，服务时间与性价比正相关
    [~,order2] = sort(tmp);
    for j = 1:candidate_service_num
        Ts(order1(j,1),i) = tmp(order2(j,1),1); % 将产生的随机数按照性价比的大小对应关系排序
    end
end
disp(Ts)
end

