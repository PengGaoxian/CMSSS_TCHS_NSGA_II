% 功能：集中定义所有实验全局参数，并完成数据加载与归一化基准计算，
%       作为 Main_MEOS.m / Main_FSGS.m 的统一参数入口脚本（用 run 调用，非函数）。
%
% 输入：（无函数输入，所有参数在脚本内直接赋值）
%   - 用户偏好参数：ordertime / Time_required_max / Cost_required_max /
%                   Quality_required_min / w_Quality / w_Cost / w_Time
%   - 平台参数：T_unit_dist / C_unit_dist / elastic_coefficient
%   - 数据文件：SimulationDataset/simulationData52.xlsx
%   - 算法参数：population_size / selection_size / gen_max /
%               cross_probability / mutation_probability
%
% 处理流程：
%   1. 设定用户偏好与平台参数，计算时间弹性上界 Time_elasticity
%   2. 从 xlsx 读取候选服务数据（extract_data），并由 Idle 推导 Occupancy（get_occupancy）
%   3. 设定遗传算法超参数
%   4. 构造距离矩阵 Distance_cell：对每个子任务的每个候选服务，
%      计算其与下一子任务所有候选服务之间的欧氏距离
%   5. 遍历 Distance_cell 求各子任务间最小物流距离之和，
%      换算为最小物流时间 total_min_Tl 和最小物流成本 total_min_Cl
%   6. 计算归一化基准：Quality_max / Time_min / Cost_min / Energy_max
%
% 输出：（工作区变量，供主程序直接使用）
%   subtask_num / candidate_service_num — 任务与服务规模
%   Q / Ts / Cs / Th / Tc / Eh        — 候选服务属性矩阵
%   Idle / P / Occupancy               — 时段数据
%   Distance_cell                      — 物流距离 cell
%   Quality_max / Time_min / Cost_min / Energy_max — 归一化基准值

rng(42); % 固定随机种子，保证实验可复现

%% 规模参数（默认值；weight_current.mat 存在时覆盖）
if exist('weight_current.mat', 'file')
    load('weight_current')
else
    subtask_num           = 10;
    candidate_service_num = 5;
    w_Quality = 0.34;
    w_Cost    = 0.33;
    w_Time    = 0.33;
end

N = subtask_num;
M = candidate_service_num;

%% 用户偏好参数
ordertime            = 60;
Time_required_max    = 80 * N;   % 随子任务数线性缩放（N=10 时=800）
Cost_required_max    = 700 * N;  % 随子任务数线性缩放（N=10 时=7000）
Quality_required_min = 0.6;

%% 平台参数
T_unit_dist         = 0.1;
C_unit_dist         = 0.1;
elastic_coefficient = 1.2;
Time_elasticity     = Time_required_max * elastic_coefficient;

%% 从 simulationData.xlsx 读取数据
file_path = fullfile(fileparts(mfilename('fullpath')), 'SimulationDataset', sprintf('scale_n%d_m%d.xlsx', N, M));
sheet = 1;
range = sprintf('A2:K%d', N*M+1);
[subtask_num,candidate_service_num,Q,Ts,Cs,Th,Tc,Eh,Idle,P] = extract_data(file_path, sheet, range);
[Occupancy] = get_occupancy(Idle,Time_elasticity);

%% 遗传算法参数
population_size = 50;
selection_size = 20;
gen_max = 10000;
cross_probability = 0.9; % 交叉概率
mutation_probability = 0.05; % 变异概率

%% 构造距离矩阵 Distance_cell [candidate_service_num × subtask_num]
% 每个元素为列向量，存储当前候选服务到下一子任务所有候选服务的欧氏距离
Distance_cell = cell(candidate_service_num,subtask_num);
for i = 1:subtask_num-1
    for j = 1:candidate_service_num
        Distance = zeros(candidate_service_num,1);
        current_position = P{j,i};
        for next_j = 1:candidate_service_num
            next_position = P{next_j,i+1};
            Distance(next_j,1) = pdist([current_position;next_position]);
        end
        Distance_cell{j,i} = Distance;
    end
end

%% 计算最小物流时间与最小物流成本（用于归一化基准 Time_min / Cost_min）
total_min_dist = 0;
for i = 1:subtask_num-1
    min_dist = Inf;
    for j = 1:candidate_service_num
        min_dist = min([min_dist;Distance_cell{j,i}]);
    end
    total_min_dist = total_min_dist + min_dist;
end
total_min_Tl = total_min_dist * T_unit_dist;
total_min_Cl = total_min_dist * C_unit_dist;

%% 计算归一化基准值（不考虑物流与等待时间的最优情形）
Quality_max = sum(max(Q,[],1))/subtask_num;
Time_min = sum(min(Ts,[],1)) + total_min_Tl;
Cost_min = sum(min(Cs,[],1)) + total_min_Cl;
Energy_max = sum(max(Eh,[],1))*2;


