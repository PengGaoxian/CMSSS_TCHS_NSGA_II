% 功能：批量生成可扩展性实验数据集。
%       对每组 (N, M) 组合将所有参数写入 scale_parameters.mat，
%       调用 generateDataset.m 生成数据，输出命名为 scale_nN_mM.xlsx。
%
% 实验规划（对应 Revision_round1.md 表1）：
%   变N组（M=10）：N = 5, 10, 15, 20
%   变M组（N=10）：M = 5, 10, 15, 20
%   N=10, M=10 为两组共享基准点，仅生成一次
%   N=10, M=5  为原始实验规模，输出 scale_n10_m5.xlsx 替代 simulationData51.xlsx 作为主实验数据集
%              simulationData51.xlsx 保留作历史参考，不再作为算法输入
%
% 注意：generateDataset.m 内含 clear，会清空工作区。
%       为保持循环状态，本脚本将循环控制变量一并写入 scale_parameters.mat，
%       generateDataset.m 加载该文件时会自动还原所有变量。

clc
clear

script_dir  = fileparts(mfilename('fullpath'));
cd(script_dir)  % 确保 pwd 与 generateDataset.m 使用的路径一致

mat_file = fullfile(script_dir, 'scale_parameters.mat');

%% 20元素全量数组（前10个与 generateDataset.m 默认值完全一致，后10个延续同一周期模式）
% 取前 N 个元素即对应 subtask_num=N 的参数，无需取模索引
full_Avg_qos = [0.7, 0.8, 0.85, 0.8, 0.7, 0.7, 0.8, 0.85, 0.8, 0.7, ...
                0.7, 0.8, 0.85, 0.8, 0.7, 0.7, 0.8, 0.85, 0.8, 0.7];
full_Std_qos = [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, ...
                0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1];
full_Avg_Cs  = [250, 500, 800, 600, 350, 250, 500, 800, 600, 350, ...
                250, 500, 800, 600, 350, 250, 500, 800, 600, 350];
full_Std_Cs  = [ 40,  30,  30,  30,  20,  40,  30,  30,  30,  20, ...
                 40,  30,  30,  30,  20,  40,  30,  30,  30,  20];
full_Avg_Ts  = [ 20,  40,  50,  30,  10,  20,  40,  50,  30,  10, ...
                 20,  40,  50,  30,  10,  20,  40,  50,  30,  10];
full_Std_Ts  = [  3,   4,   4,   4,   2,   3,   4,   4,   4,   2, ...
                  3,   4,   4,   4,   2,   3,   4,   4,   4,   2];

%% 固定参数（与 global_parameters_block 保持一致）
Tsu_ratio_Tm        = 0.1;
elastic_coefficient = 1.2;
range               = 100;

%% (N, M) 组合：N = 子任务数，M = 候选服务数
configs = [
     5, 10;   % 变N组
    10, 10;   % 变N / 变M 共享基准
    15, 10;   % 变N组
    20, 10;   % 变N组
    10,  5;   % 变M组；同时也是原始基准规模（替代 simulationData51.xlsx）
    10, 15;   % 变M组
    10, 20;   % 变M组
];

%% 逐组生成数据集
% 使用 while 而非 for，因为 generateDataset.m 内的 clear 会清空工作区；
% 循环状态变量随参数一起存入 scale_parameters.mat，load 后自动还原。
ii = 1;
while ii <= size(configs, 1)
    N = configs(ii, 1);
    M = configs(ii, 2);

    % 取前 N 个元素构造本组参数
    subtask_num           = N;
    candidate_service_num = M;
    deadline      = 80 * N;  % 随子任务数线性缩放（N=10 时 deadline=800）
    Avg_qos       = full_Avg_qos(1:N);
    Std_qos       = full_Std_qos(1:N);
    Avg_Cs        = full_Avg_Cs(1:N);
    Std_Cs        = full_Std_Cs(1:N);
    Avg_Ts        = full_Avg_Ts(1:N);
    Std_Ts        = full_Std_Ts(1:N);
    Avg_idle_rate = ones(1, N) * 0.5;
    Std_idle_rate = ones(1, N) * 0.1;
    filename      = sprintf('scale_n%d_m%d.xlsx', N, M);

    % 将数据集参数 + 循环状态一并保存
    % generateDataset.m 执行 clear 后会 load 此文件，还原所有变量
    save(mat_file, ...
        'subtask_num', 'candidate_service_num', ...
        'Avg_qos', 'Std_qos', 'Avg_Cs', 'Std_Cs', 'Avg_Ts', 'Std_Ts', ...
        'Tsu_ratio_Tm', 'deadline', 'elastic_coefficient', ...
        'Avg_idle_rate', 'Std_idle_rate', 'range', 'filename', ...
        'ii', 'configs', ...
        'script_dir', 'mat_file', ...
        'full_Avg_qos', 'full_Std_qos', 'full_Avg_Cs', 'full_Std_Cs', ...
        'full_Avg_Ts', 'full_Std_Ts');

    run(fullfile(script_dir, 'generateDataset.m'))
    % generateDataset.m 执行了 clear，然后 load(scale_parameters.mat)，
    % 工作区已还原上方所有变量（包括 ii、N、M、configs 等）

    % 清理临时参数文件
    delete(mat_file)

    fprintf('生成完成：%s\n', filename)
    ii = ii + 1;
end

fprintf('\n全部数据集生成完毕（共 %d 个）。\n', size(configs, 1))
