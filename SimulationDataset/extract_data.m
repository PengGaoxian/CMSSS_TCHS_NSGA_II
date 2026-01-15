%% 读取xlsx文件，获取变量值
% 输入参数：
%   file_path：xlsx文件位置
%   sheet：xlsx文件的表单号
%   range：数据提取范围
%   subtask_num：子任务的数量
%   candidata_service_num：候选服务的数量
% 输出参数：
%   Q：候选服务的质量
%   Ts：候选服务的服务时长
%   Cs：候选服务的服务成本
%   Tsu：候选服务的启动时长
%   Tsd：候选服务的关停时长
%   Esu：候选服务的启动成本
%   Idle：候选服务的服务空闲时间段
function [subtask_num,candidate_service_num,Q,Ts,Cs,Tsu,Tsd,Esu,Idle,P] = extract_data(file_path, sheet, range)
    %% 数值数据存放在Dataset变量中，文本数据存放在Text中
    [Dataset,Text] = xlsread(file_path, sheet, range); 
    %% 数值数据提取
    subtask_num = Dataset(1,1);
    candidate_service_num = Dataset(1,2);
    Q = reshape(Dataset(:,4), candidate_service_num, subtask_num);
    Ts = reshape(Dataset(:,5), candidate_service_num, subtask_num);
    Cs = reshape(Dataset(:,6), candidate_service_num, subtask_num);
    Tsu = reshape(Dataset(:,7), candidate_service_num, subtask_num);
    Tsd = reshape(Dataset(:,8), candidate_service_num, subtask_num);
    Esu = reshape(Dataset(:,9), candidate_service_num, subtask_num);
    %% 文本数据提取
    Idle = cell(candidate_service_num,subtask_num);
    for i = 1:subtask_num*candidate_service_num
        Idle{i} = eval(Text{i,8}); % 字符串转矩阵
    end
    P = cell(candidate_service_num,subtask_num);
    for i = 1:subtask_num*candidate_service_num
        P{i} = eval(Text{i,9}); % 字符串转矩阵
    end
end