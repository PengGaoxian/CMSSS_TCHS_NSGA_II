% 功能：从仿真数据集 xlsx 文件中读取候选服务参数及时间占用信息，
%       构建后续调度算法所需的数值矩阵与空闲时段 cell 数组。
%
% 输入：
%   file_path            - xlsx 文件路径
%   sheet                - 读取的表单编号
%   range                - 数据提取范围（如 'A1:K100'）
%
% 处理流程：
%   1. 用 readcell 读取原始数据（避免依赖 Excel COM 服务）
%   2. 提取数值列，构造 Dataset 矩阵；
%      第 1 行第 1/2 列分别为 subtask_num / candidate_service_num
%   3. 将第 4–9 列按 [candidate_service_num × subtask_num] reshape，
%      依次得到 Q / Ts / Cs / Tsu / Tsd / Esu
%   4. 第 10 列为空闲时段字符串，逐行 eval 解析为数值向量，存入 Idle cell 数组
%   5. 第 11 列为占用时段字符串，逐行 eval 解析为数值向量，存入 P cell 数组
%
% 输出：
%   subtask_num          - 子任务数量
%   candidate_service_num - 每个子任务的候选服务数量
%   Q                    - 服务质量矩阵 [candidate_service_num × subtask_num]
%   Ts                   - 服务时长矩阵 [candidate_service_num × subtask_num]
%   Cs                   - 服务成本矩阵 [candidate_service_num × subtask_num]
%   Tsu                  - 启动时长矩阵 [candidate_service_num × subtask_num]
%   Tsd                  - 关停时长矩阵 [candidate_service_num × subtask_num]
%   Esu                  - 启动能耗矩阵 [candidate_service_num × subtask_num]
%   Idle                 - 空闲时段 cell [candidate_service_num × subtask_num]，每元素为列向量
%   P                    - 占用时段 cell [candidate_service_num × subtask_num]，每元素为列向量
function [subtask_num,candidate_service_num,Q,Ts,Cs,Tsu,Tsd,Esu,Idle,P] = extract_data(file_path, sheet, range)
    %% 用 readcell 读取（不依赖 Excel COM 服务）
    raw = readcell(file_path, 'Sheet', sheet, 'Range', range, 'UseExcel', false);
    %% 数值数据提取
    numCols = cellfun(@(x) isnumeric(x) && isscalar(x), raw);
    Dataset = zeros(size(raw));
    Dataset(numCols) = cell2mat(raw(numCols));
    subtask_num = Dataset(1,1);
    candidate_service_num = Dataset(1,2);
    Q = reshape(Dataset(:,4), candidate_service_num, subtask_num);
    Ts = reshape(Dataset(:,5), candidate_service_num, subtask_num);
    Cs = reshape(Dataset(:,6), candidate_service_num, subtask_num);
    Tsu = reshape(Dataset(:,7), candidate_service_num, subtask_num);
    Tsd = reshape(Dataset(:,8), candidate_service_num, subtask_num);
    Esu = reshape(Dataset(:,9), candidate_service_num, subtask_num);
    %% 文本数据提取（第10列=Idle，第11列=P）
    Idle = cell(candidate_service_num, subtask_num);
    for i = 1:subtask_num*candidate_service_num
        Idle{i} = eval(char(raw{i, 10}));
    end
    P = cell(candidate_service_num, subtask_num);
    for i = 1:subtask_num*candidate_service_num
        P{i} = eval(char(raw{i, 11}));
    end
end