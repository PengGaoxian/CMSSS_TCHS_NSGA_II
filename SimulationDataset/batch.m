%% 生成不同占用比的模拟数据集
clc
clear

Time_required_max = 800;
elastic_coefficient = 1.2;
Time_elasticity = Time_required_max*elastic_coefficient;
subtask_num = 10;

Avg_Std_idle = [ % 第一列为占用比的均值，第二列为标准差
%                 0.2,0.1;
%                 0.3,0.1;
%                 0.4,0.1;
%                 0.5,0.1;
                0.5,0.2;
%                 0.6,0.1;
%                 0.6,0.2;
%                 0.7,0.1;
%                 0.7,0.2;
%                 0.7,0.3;
%                 0.8,0.1;
                ];

%% 生成不同占用比率的数据集
source_file = 'simulationData.xlsx';
for ii = 1:size(Avg_Std_idle,1)
    Avg_idle_rate = ones(1,subtask_num)*Avg_Std_idle(ii,1); % 子任务对应候选服务集的平均空闲率
    Std_idle_rate = ones(1,subtask_num)*Avg_Std_idle(ii,2); % 子任务对应候选服务集的空闲率标准差
    save('idle_rate.mat','Avg_idle_rate','Std_idle_rate')
    save('current_parameters')
    generateDataset
    load('current_parameters')
    objective_file = ['simulationData',num2str(Avg_Std_idle(ii,1)*10),num2str(Avg_Std_idle(ii,2)*10),'.xlsx'];
    movefile(source_file,objective_file)
end
%% 画出占用甘特图
for ii = 1:size(Avg_Std_idle,1)
    file_name = ['simulationData',num2str(Avg_Std_idle(ii,1)*10),num2str(Avg_Std_idle(ii,2)*10),'.xlsx'];
    sheet = 'Sheet1';
    range = 'A2:K51';
    [subtask_num,candidate_service_num,Q,Ts,Cs,Th,Tc,Eh,Idle,P] = extract_data(file_name, sheet, range);
    [Occupancy] = get_occupancy(Idle,Time_elasticity);
    
    title = file_name;
    figure
    paint_occupancy(Occupancy,Time_elasticity,title); % 画出占用时间的甘特图
end
