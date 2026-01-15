%% 生成子任务对应的候选服务的启动时长、关停时长、启动成本的数据集
function [Tsu,Tsd,Esu] = generate_Tsu_Tsd_Esu(Cs,Ts,Avg_Tsu,Std_Tsu)
[candidate_service_num,subtask_num] = size(Cs);
% 定义候选服务集的服务价格数据矩阵
Tsu = zeros(candidate_service_num,subtask_num); % 服务价格矩阵
for i = 1:subtask_num 
    % 生成均值为Tsu_avg_on_mcs，标准差为Tsu_std_on_mcs的正态分布的MCS_i集合数据
    Tsu(:,i) = normrnd(Avg_Tsu(1,i), Std_Tsu(1,i), candidate_service_num, 1);
end
disp(Tsu);
%% 候选服务关停时长：启动时长的2倍
Tsd_ratio_Tsu = 2;
Tsd = Tsu * Tsd_ratio_Tsu;
disp(Tsd);
%% 候选服务的启动成本：单位时间的服务成本*启动时长
Esu_ratio_Tsu = Cs ./ Ts;
Esu = Tsu .* Esu_ratio_Tsu;
disp(Esu);
end

