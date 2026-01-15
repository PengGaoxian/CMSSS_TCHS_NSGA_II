%% 生成候选服务的成本数据集（成本与质量正相关）
% 输入
%   Q：候选服务的质量数据集
%   Avg_Cs：子任务对应的候选服务的成本均值
%   Std_Cs：子任务对应的候选服务的成本标准差
% 输出
%   Cs：候选服务的成本数据集
function [Cs] = generate_Cs(Q,Avg_Cs,Std_Cs)
[candidate_service_num,subtask_num] = size(Q);
% 定义候选服务集的服务价格数据矩阵
Cs = zeros(candidate_service_num,subtask_num); % 服务价格矩阵
tmp = zeros(candidate_service_num,1);
for i = 1:subtask_num
    % 生成均值为Cm_avg_on_mcs，标准差为Cm_std_on_mcs的正态分布的MCS_i集合数据
    tmp(:,1) = normrnd(Avg_Cs(1,i), Std_Cs(1,i), candidate_service_num, 1);
    [~,order1] = sort(Q(:,i)); % 质量排序，成本与质量正相关
    [~,order2] = sort(tmp);
    for j = 1:candidate_service_num
        Cs(order1(j,1),i) = tmp(order2(j,1),1); % 将产生的随机数按照qos的大小对应关系排序，质量与价格正相关
    end
end
disp(Cs);
end

