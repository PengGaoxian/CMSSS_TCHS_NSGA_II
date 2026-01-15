%% 计算种群中每个个体对应的子任务的运输开始时间和运输结束时间
% 输入
%   End_candidate_service：种群中每个个体对应的子任务的完成时间
%   Tl：种群中每个个体对应的子任务两两之间的运输时间
% 输出
%   Start_logistic：种群中每个个体对应的子任务的运输开始时间
%   End_logistic：种群中每个个体对应的子任务的运输结束时间
function [Start_logistic,End_logistic] = Start_End_logistics(End_candidate_service,Tl)
Start_logistic = End_candidate_service;
End_logistic = End_candidate_service+Tl;
end

