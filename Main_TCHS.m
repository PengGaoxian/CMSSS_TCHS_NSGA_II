% 功能：后处理合并 MEOS 与 EOS 的帕累托前沿，重新计算联合帕累托前沿（TCHS 策略）。
%       对已收敛的两条前沿取"外包络"——每个前沿点要么来自 MEOS，要么来自 EOS。
%
% 运行模式：
%   单独运行  — 加载 outputs/Data_MEOS.mat 与 outputs/Data_EOS.mat（无后缀）
%   paint_Data.m 批量调用 — 从工作区继承 dirname/ii/Filename_postfix，
%                           加载 MEOS/EOS 各自已重命名的带后缀文件
%
% 输出：（保存至 outputs/Data_TCHS.mat，供 paint_Data.m 的 movefile 重命名后加载绘图）
%   Population_front_last 及各衍生变量 — 联合帕累托前沿的种群与时间信息

%% 确定输入文件路径（批量调用 vs 单独运行）
if exist('dirname', 'var') && exist('ii', 'var') && exist('Filename_postfix', 'var')
    % paint_Data.m 调用：jj 循环结束时 MEOS/EOS 已被 movefile 重命名，使用带后缀文件
    outputs_dir = dirname;
    postfix   = strtrim(Filename_postfix(ii, :));
    meos_file = strcat(dirname, 'Data_MEOS-', postfix, '.mat');
    eos_file  = strcat(dirname, 'Data_EOS-',  postfix, '.mat');
else
    % 单独运行：加载无后缀文件，并补充加载全局参数
    global_parameters_block
    outputs_dir = fullfile(fileparts(mfilename('fullpath')), sprintf('outputs_n%d_m%d', subtask_num, candidate_service_num));
    meos_file = fullfile(outputs_dir, 'Data_MEOS.mat');
    eos_file  = fullfile(outputs_dir, 'Data_EOS.mat');
end

%% 加载 MEOS 最后一代前沿数据
s_MEOS = load(meos_file);
Pop_MEOS       = s_MEOS.Population_front_last;
Fit_MEOS       = s_MEOS.Population_front_last_Fitness_value;
Start_cs_MEOS  = s_MEOS.Population_front_last_Start_candidate_service;
End_cs_MEOS    = s_MEOS.Population_front_last_End_candidate_service;
Start_log_MEOS = s_MEOS.Population_front_last_Start_logistics;
End_log_MEOS   = s_MEOS.Population_front_last_End_logistics;

%% 加载 EOS 最后一代前沿数据
s_EOS = load(eos_file);
Pop_EOS       = s_EOS.Population_front_last;
Fit_EOS       = s_EOS.Population_front_last_Fitness_value;
Start_cs_EOS  = s_EOS.Population_front_last_Start_candidate_service;
End_cs_EOS    = s_EOS.Population_front_last_End_candidate_service;
Start_log_EOS = s_EOS.Population_front_last_Start_logistics;
End_log_EOS   = s_EOS.Population_front_last_End_logistics;

%% 逐代计算 TCHS 联合前沿 HV（逐代合并 MEOS+EOS 前沿取外包络）
PF_MEOS    = s_MEOS.Populations_front_Fitness_value;
PF_EOS     = s_EOS.Populations_front_Fitness_value;
HV_history = zeros(length(PF_MEOS), 1);
for g = 1:length(PF_MEOS)
    F_g      = [PF_MEOS{g,1}; PF_EOS{g,1}];
    [F_g, ~] = unique(F_g, 'rows', 'stable');
    fn_g     = pareto_front(F_g);
    HV_history(g) = compute_hv(F_g(fn_g==1, :), [1.1, 1.1]);
end

%% 合并两组前沿
Combined_Pop       = [Pop_MEOS;       Pop_EOS      ];
Combined_Fitness   = [Fit_MEOS;       Fit_EOS      ];
Combined_Start_cs  = [Start_cs_MEOS;  Start_cs_EOS ];
Combined_End_cs    = [End_cs_MEOS;    End_cs_EOS   ];
Combined_Start_log = [Start_log_MEOS; Start_log_EOS];
Combined_End_log   = [End_log_MEOS;   End_log_EOS  ];

%% 去除适应度重复点（严格支配定义下重复点互不支配，保留会虚增前沿点数）
[Combined_Fitness, ia] = unique(Combined_Fitness, 'rows', 'stable');
Combined_Pop       = Combined_Pop(ia, :);
Combined_Start_cs  = Combined_Start_cs(ia, :);
Combined_End_cs    = Combined_End_cs(ia, :);
Combined_Start_log = Combined_Start_log(ia, :);
Combined_End_log   = Combined_End_log(ia, :);

%% 重新计算联合帕累托前沿
front_num   = pareto_front(Combined_Fitness);
front_index = find(front_num == 1);

%% 提取联合帕累托前沿
Population_front_last                         = Combined_Pop(front_index, :);
Population_front_last_Fitness_value           = Combined_Fitness(front_index, :);
Population_front_last_Start_candidate_service = Combined_Start_cs(front_index, :);
Population_front_last_End_candidate_service   = Combined_End_cs(front_index, :);
Population_front_last_Start_logistics         = Combined_Start_log(front_index, :);
Population_front_last_End_logistics           = Combined_End_log(front_index, :);

%% 提取前沿点指标（直接存入 .mat，供 paint_Data.m 使用）
QoS_Fitness    = Population_front_last_Fitness_value(:,2);
Energy_Fitness = Population_front_last_Fitness_value(:,1);
[~, Cl_front]  = logistics(Population_front_last, Distance_cell, T_unit_dist, C_unit_dist);
[Quality, Cost, Time] = criteria(Population_front_last, Q, Cs, Population_front_last_End_candidate_service, Cl_front);
E_front        = preheating_energy(Eh, Population_front_last, Th, Tc, Idle, Population_front_last_Start_candidate_service, Population_front_last_End_candidate_service);
Energy_Raw     = sum(E_front, 2);
HV             = compute_hv(Population_front_last_Fitness_value, [1.1, 1.1]);

%% 保存
save(fullfile(outputs_dir, 'Data_TCHS.mat'), ...
    'Population_front_last', ...
    'Population_front_last_Fitness_value', ...
    'Population_front_last_Start_candidate_service', ...
    'Population_front_last_End_candidate_service', ...
    'Population_front_last_Start_logistics', ...
    'Population_front_last_End_logistics', ...
    'gen_max', 'population_size', ...
    'QoS_Fitness', 'Energy_Fitness', 'Quality', 'Cost', 'Time', 'Energy_Raw', 'HV', 'HV_history');
