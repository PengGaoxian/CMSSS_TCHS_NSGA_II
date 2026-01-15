clear
clc
%% 全局参数设置
subtask_num = 10; % 任务分解成子任务的个数
candidate_service_num = 5; % 每个子任务对应的候选服务的个数
%% 生成候选服务质量数据集
Avg_qos = [0.7, 0.8, 0.85, 0.8, 0.7, 0.7, 0.8, 0.85, 0.8, 0.7]; % 子任务对应的候选服务的质量均值
Std_qos = [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1]; % 子任务对应的候选服务的质量标准差
Q = generate_Q(subtask_num,candidate_service_num,Avg_qos,Std_qos);
%% 生成候选服务成本数据集（成本与质量正相关）
Avg_Cs = [250, 500, 800, 600, 350, 250, 500, 800, 600, 350]; % 子任务对应的候选服务的成本均值
Std_Cs = [40, 30, 30, 30, 20, 40, 30, 30, 30, 20]; % 子任务对应的候选服务的成本标准差
Cs = generate_Cs(Q,Avg_Cs,Std_Cs);
%% 生成候选服务的服务时长数据集（时长与性价比成正比）
Avg_Ts = [20, 40, 50, 30, 10, 20, 40, 50, 30, 10]; % 子任务对应的候选服务的服务时长均值
Std_Ts = [3, 4, 4, 4, 2, 3, 4, 4, 4, 2]; % 子任务对应的候选服务的服务时长标准差
Ts = generate_Ts(Q,Cs,Avg_Ts,Std_Ts);
%% 生成服务启动时长、关停时长、启动成本的数据集
Tsu_ratio_Tm = 0.1;
Avg_Tsu = Avg_Ts * Tsu_ratio_Tm; % 候选服务启动时长的均值
Std_Tsu = Std_Ts * Tsu_ratio_Tm; % 候选服务启动时长的标准差
[Tsu,Tsd,Esu] = generate_Tsu_Tsd_Esu(Cs,Ts,Avg_Tsu,Std_Tsu);
%% 生成候选服务的空闲时间段数据集
deadline = 800; % 用户要求完成任务的最迟时间deadline【与global_parameters_block中的参数保持一致】
elastic_coefficient = 1.2; %【与global_parameters_block中的参数保持一致】
Time_elasticity = deadline*elastic_coefficient;
max_occupancy_num = subtask_num;
min_occupancy_num = ceil(max_occupancy_num*0.3);

Avg_idle_rate = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]; % 子任务对应候选服务集的平均空闲率
Std_idle_rate = [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1]; % 子任务对应候选服务集的空闲率标准差
% 如果存在idle_rate.mat文件则使用文件中的变量替换Avg_idle_rate和Std_idle_rate
if exist(strcat(pwd, "\idle_rate.mat"),'file') ~= 0
    load(strcat(pwd, "\idle_rate.mat"))
end
[Idle,Occupancy,Occupancy_rate] = generate_Idle(Q,Time_elasticity,min_occupancy_num,max_occupancy_num,Avg_idle_rate,Std_idle_rate);
title = ['gantt',num2str(Avg_idle_rate(1,1)*10),num2str(Std_idle_rate(1,1)*10)];
% figure
% paint_occupancy(Occupancy,Time_elasticity,title); % 画出占用时间的甘特图
%% 生成候选服务的位置坐标数据集
range = 100;
P = generate_P(Q,range);
%% 清空文件，然后写入文件
file_path = strcat(pwd, "\simulationData.xlsx");
if exist(file_path,'file') ~= 0
    delete(file_path); % 删除原文件
end
% file_path = 'C:\Users\Administrator\Documents\我的坚果云\A博士文件\A科研工作\00科技论文写作指南\Matlab\任务衔接度【不考虑物流】（遗传算法）\simulationData.xlsx';
col_name = ["subtask_num","candidate_service_num","MCS_i^j","Q","Ts","Cs","Tsu","Tsd","Esu","Idle","P"];
row_name = strings(subtask_num*candidate_service_num,1);
for i = 1:subtask_num
    for j = 1:candidate_service_num
        row_name((i-1)*candidate_service_num+j,1) = "i="+i+',j='+j;
    end
end
Idle_strings = "";
for i = 1:numel(Idle)
    Idle_strings(i,1) = mat2str(Idle{i});
end
P_strings = "";
for i = 1:numel(P)
    P_strings(i,1) = mat2str(P{i});
end
writematrix(col_name, file_path,'Sheet',1,'Range','A1:K1');
writematrix([subtask_num,candidate_service_num], file_path, 'Sheet',1,'Range','A2:B2');
writematrix(row_name, file_path,'Sheet',1,'Range','C2');
writematrix(Q(:), file_path,'Sheet',1,'Range','D2');
writematrix(Ts(:), file_path,'Sheet',1,'Range','E2');
writematrix(Cs(:), file_path,'Sheet',1,'Range','F2');
writematrix(Tsu(:), file_path,'Sheet',1,'Range','G2');
writematrix(Tsd(:), file_path,'Sheet',1,'Range','H2');
writematrix(Esu(:), file_path,'Sheet',1,'Range','I2');
writematrix(Idle_strings(:), file_path,'Sheet',1,'Range','J2');
writematrix(P_strings(:), file_path,'Sheet',1,'Range','K2');