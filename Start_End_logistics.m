% 功能：根据服务执行结束时间和物流时长，计算种群中每个个体各子任务的物流开始与结束时间。
%       物流紧接服务执行结束后开始，用于甘特图绘制与调度时序记录。
%
% 输入：
%   End_candidate_service - 服务执行结束时间矩阵 [population_size × subtask_num]
%   Tl                    - 物流时长矩阵 [population_size × subtask_num]，由 logistics 计算
%
% 处理流程：
%   Start_logistic = End_candidate_service        （物流开始时间 = 服务结束时间）
%   End_logistic   = End_candidate_service + Tl   （物流结束时间 = 服务结束时间 + 物流时长）
%
% 输出：
%   Start_logistic - 物流开始时间矩阵 [population_size × subtask_num]
%   End_logistic   - 物流结束时间矩阵 [population_size × subtask_num]
function [Start_logistic,End_logistic] = Start_End_logistics(End_candidate_service,Tl)
Start_logistic = End_candidate_service;
End_logistic = End_candidate_service+Tl;
end

