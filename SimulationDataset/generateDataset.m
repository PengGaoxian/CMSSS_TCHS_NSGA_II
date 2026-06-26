% 功能：生成云制造服务选择与调度仿真实验的基础数据集，包括候选服务的质量、成本、时长、
%       启停参数、空闲时段及位置坐标，并将结果写入 simulationData.xlsx。
%       生成的数据集供 global_parameters_block.m 加载后用于各调度算法（Main_*.m）的仿真实验。
%
% 输入：（无函数输入，所有参数直接在脚本中硬编码，修改时在脚本内调整）
%   subtask_num           - 子任务数量（默认 10）
%   candidate_service_num - 每个子任务的候选服务数量（默认 5）
%   Avg_qos               - 各子任务服务质量均值向量 [1×subtask_num]（默认 0.7~0.85 循环）
%   Std_qos               - 各子任务服务质量标准差向量 [1×subtask_num]（默认 0.1）
%   Avg_Cs                - 各子任务服务成本均值向量 [1×subtask_num]（默认 250~800 循环，单位与 Cost_required_max 一致）
%   Std_Cs                - 各子任务服务成本标准差向量 [1×subtask_num]
%   Avg_Ts                - 各子任务服务时长均值向量 [1×subtask_num]（默认 10~50 循环，单位与 deadline 一致）
%   Std_Ts                - 各子任务服务时长标准差向量 [1×subtask_num]
%   Tsu_ratio_Tm          - 启动时长与服务时长的比值（默认 0.1，即启动时长 = 10% × 服务时长）
%   deadline              - 任务最迟完成时间（默认 800，须与 global_parameters_block 保持一致）
%   elastic_coefficient   - 时间弹性系数（默认 1.2，须与 global_parameters_block 保持一致）
%   Avg_idle_rate         - 各子任务候选服务空闲率均值向量 [1×subtask_num]（默认 0.5）
%   Std_idle_rate         - 各子任务候选服务空闲率标准差向量 [1×subtask_num]（默认 0.1）
%   range                 - 候选服务地理位置坐标范围（默认 100，生成 range×range 区域内的随机坐标）
%   scale_parameters.mat（可选） - 若文件存在则整体加载（批量实验由外部脚本提前生成），否则使用上述 13 个默认值
%
% 处理流程：
%   1. 生成服务质量矩阵 Q（generate_Q）：按子任务均值/标准差随机采样
%   2. 生成服务成本矩阵 Cs（generate_Cs）：与质量正相关
%   3. 生成服务时长矩阵 Ts（generate_Ts）：与性价比成正比
%   4. 生成启停参数（generate_Tsu_Tsd_Esu）：预热时长 Tsu、冷却时长 Tsd、启动能耗 Esu
%   5. 生成空闲时段数据（generate_Idle）：按空闲率生成每个候选服务的可用时段 Idle 及占用记录 Occupancy
%   6. 生成位置坐标（generate_P）：在 range×range 区域内随机分布各服务地理位置
%   7. 将全部数据写入 simulationData.xlsx（先删除旧文件再写入，避免残留脏数据）
%
% 输出：
%   simulationData.xlsx — 包含所有候选服务数据的 Excel 文件，列顺序：
%                         subtask_num / candidate_service_num / MCS_i^j /
%                         Q / Ts / Cs / Tsu / Tsd / Esu / Idle / P

clear
clc
rng(42);  % 固定随机种子，确保每次生成相同数据集

%% 可调参数
if exist(strcat(pwd, "\scale_parameters.mat"), 'file')
    load(strcat(pwd, "\scale_parameters.mat"))
else
    subtask_num           = 10;  % 子任务数量
    candidate_service_num = 5;   % 每个子任务的候选服务数量

    Avg_qos = [0.7, 0.8, 0.85, 0.8, 0.7, 0.7, 0.8, 0.85, 0.8, 0.7]; % 各子任务服务质量均值
    Std_qos = [0.1, 0.1,  0.1, 0.1, 0.1, 0.1, 0.1,  0.1, 0.1, 0.1]; % 各子任务服务质量标准差

    Avg_Cs = [250, 500, 800, 600, 350, 250, 500, 800, 600, 350]; % 各子任务服务成本均值
    Std_Cs = [ 40,  30,  30,  30,  20,  40,  30,  30,  30,  20]; % 各子任务服务成本标准差

    Avg_Ts = [20, 40, 50, 30, 10, 20, 40, 50, 30, 10]; % 各子任务服务时长均值
    Std_Ts = [ 3,  4,  4,  4,  2,  3,  4,  4,  4,  2]; % 各子任务服务时长标准差

    Tsu_ratio_Tm        = 0.1;  % 启动时长与服务时长的比值
    deadline            = 800;  % 任务最迟完成时间（须与 global_parameters_block 保持一致）
    elastic_coefficient = 1.2;  % 时间弹性系数（须与 global_parameters_block 保持一致）

    Avg_idle_rate = ones(1, subtask_num) * 0.5; % 各子任务候选服务空闲率均值
    Std_idle_rate = ones(1, subtask_num) * 0.1; % 各子任务候选服务空闲率标准差

    range    = 100;                  % 候选服务地理位置坐标范围
    filename = 'simulationData.xlsx'; % 输出文件名
end

%% 生成各属性矩阵（以下无需修改）
Q  = generate_Q(subtask_num, candidate_service_num, Avg_qos, Std_qos);
Cs = generate_Cs(Q, Avg_Cs, Std_Cs);
Ts = generate_Ts(Q, Cs, Avg_Ts, Std_Ts);

Avg_Tsu = Avg_Ts * Tsu_ratio_Tm; % 候选服务启动时长均值（由 Avg_Ts 推导）
Std_Tsu = Std_Ts * Tsu_ratio_Tm; % 候选服务启动时长标准差（由 Std_Ts 推导）
[Tsu, Tsd, Esu] = generate_Tsu_Tsd_Esu(Cs, Ts, Avg_Tsu, Std_Tsu);

Time_elasticity   = deadline * elastic_coefficient;
max_occupancy_num = subtask_num;
min_occupancy_num = ceil(max_occupancy_num * 0.3);
[Idle, Occupancy, Occupancy_rate] = generate_Idle(Q, Time_elasticity, min_occupancy_num, max_occupancy_num, Avg_idle_rate, Std_idle_rate);
% figure
% paint_occupancy(Occupancy, Time_elasticity, ['gantt', num2str(Avg_idle_rate(1)*10), num2str(Std_idle_rate(1)*10)]);

P = generate_P(Q, range);

%% 清空文件，然后写入文件
file_path = fullfile(pwd, filename);
if exist(file_path, 'file') ~= 0
    delete(file_path);
end
col_name = ["subtask_num","candidate_service_num","MCS_i^j","Q","Ts","Cs","Tsu","Tsd","Esu","Idle","P"];
row_name = strings(subtask_num * candidate_service_num, 1);
for i = 1:subtask_num
    for j = 1:candidate_service_num
        row_name((i-1)*candidate_service_num+j, 1) = "i="+i+',j='+j;
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
writematrix(col_name, file_path, 'Sheet', 1, 'Range', 'A1:K1');
writematrix([subtask_num, candidate_service_num], file_path, 'Sheet', 1, 'Range', 'A2:B2');
writematrix(row_name,        file_path, 'Sheet', 1, 'Range', 'C2');
writematrix(Q(:),            file_path, 'Sheet', 1, 'Range', 'D2');
writematrix(Ts(:),           file_path, 'Sheet', 1, 'Range', 'E2');
writematrix(Cs(:),           file_path, 'Sheet', 1, 'Range', 'F2');
writematrix(Tsu(:),          file_path, 'Sheet', 1, 'Range', 'G2');
writematrix(Tsd(:),          file_path, 'Sheet', 1, 'Range', 'H2');
writematrix(Esu(:),          file_path, 'Sheet', 1, 'Range', 'I2');
writematrix(Idle_strings(:), file_path, 'Sheet', 1, 'Range', 'J2');
writematrix(P_strings(:),    file_path, 'Sheet', 1, 'Range', 'K2');
