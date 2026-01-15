%% 生成候选服务的位置坐标数据集
% 输入
%   Q：候选服务的服务质量数据集
%   range：坐标的范围
% 输出
%   P：候选服务位置的坐标数据集
function [P] = generate_P(Q,range)
[candidate_service_num,subtask_num] = size(Q);
P_x = randi(range,candidate_service_num,subtask_num);
P_y = randi(range,candidate_service_num,subtask_num);
P = cell(candidate_service_num,subtask_num);
for i = 1:subtask_num
    for j = 1:candidate_service_num
        P{j,i}(1,1) = P_x(j,i);
        P{j,i}(1,2) = P_y(j,i);
    end
end
disp(P);
end

