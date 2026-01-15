%% 生成候选服务可用时间段的数据集
% 输入
%   Q：候选服务的服务质量数据集
%   Time_elasticity：ordertime~deadline区间扩展后的时间
%   min_occupancy_num：最小占用段数
%   max_occupancy_num：最大占用段数
%   Avg_occupancy_rate：候选服务集的平均占用率
%   Std_occupancy_rate：候选服务集占用率标准差
% 输出
%   Idle：空闲时间cell矩阵
%   Occupancy：占用时间cell矩阵
%   Occupancy_rate：占用率
function [Idle,Occupancy,Occupancy_rate] = generate_Idle(Q,Time_elasticity,min_occupancy_num,max_occupancy_num,Avg_Occupancy_rate,Std_Occupancy_rate)
[candidate_service_num,subtask_num] = size(Q);
Idle = cell(candidate_service_num,subtask_num); % 服务空闲时间段的元胞数组

Occupancy_rate = zeros(candidate_service_num,subtask_num); % 服务空闲率矩阵
for i = 1:subtask_num 
    % 生成均值为Avg_idle_rate，标准差为Std_idle_rate的正态分布的MCS_i集合数据
    Occupancy_rate(:,i) = normrnd(Avg_Occupancy_rate(1,i), Std_Occupancy_rate(1,i), candidate_service_num, 1);
    
end
Occupancy_rate(find(Occupancy_rate<0)) = 0;
Occupancy = cell(candidate_service_num,subtask_num);
for i = 1:subtask_num 
    for j = 1:candidate_service_num
        occupancy_time = ceil(Time_elasticity * Occupancy_rate(j,i)); % 根据占用率计算总占用时间
        actual_occupancy_num = randi([min_occupancy_num,max_occupancy_num]); % 随机产生实际占用时间段的段数
        % 调整占用时间段的段数
        if occupancy_time == 0
            actual_occupancy_num = 0;
        elseif occupancy_time < (actual_occupancy_num*Time_elasticity*0.01)
            actual_occupancy_num = ceil(occupancy_time/(Time_elasticity*0.01));
        end
        % 将占用时间随机分为actual_occupancy_num段
        if actual_occupancy_num ~= 0
            Point_occupancy = randperm(occupancy_time,actual_occupancy_num-1); % 在占用时间中打断点
            Point_occupancy_sort = [0,sort(Point_occupancy),occupancy_time]; % 将断点从小到大排序
            % 用Occupancy_duration表示总占用时间分块后的占用持续时间矩阵
            Occupancy_duration = zeros(1,actual_occupancy_num);
            for k = 1:actual_occupancy_num
                Occupancy_duration(1,k) = Point_occupancy_sort(1,k+1) - Point_occupancy_sort(1,k);
            end
            Point_Time_elasticity = randperm(Time_elasticity, actual_occupancy_num); % 在全时间段上随机选出actual_occupancy_num个点
            Point_occupancy_sort = sort(Point_Time_elasticity); % 全时间段上的断点排序
        
            %% 计算占用时间Occupancy
            Occupancy_candidate_service = zeros(2,actual_occupancy_num); % 用于存放某一候选服务全长时间上的占用
            for k = 1:actual_occupancy_num
                Occupancy_candidate_service(1,k) = Point_occupancy_sort(1,k); % 第k段占用开始时间
                Occupancy_candidate_service(2,k) = Occupancy_candidate_service(1,k) + Occupancy_duration(1,k); % 第k段占用结束时间
                % 前后占用的重叠部分向后顺延
                if k>=2 && Occupancy_candidate_service(1,k)<Occupancy_candidate_service(2,k-1)
                    Occupancy_candidate_service(1,k) = Occupancy_candidate_service(2,k-1); % 开始时间
                    Occupancy_candidate_service(2,k) = Occupancy_candidate_service(1,k) + Occupancy_duration(1,k); % 结束时间
                end
            end
            Occupancy{j,i} = Occupancy_candidate_service;

            %% 计算空闲时间Idle
            Occupancy_start = [0,Occupancy_candidate_service(2,:)];
            Occupancy_end = [Occupancy_candidate_service(1,:),Time_elasticity];
            Occupancy_combine = [Occupancy_start;Occupancy_end];
            temp = size(Occupancy_combine,2);
            while temp > 0
                if Occupancy_combine(1,temp) == Occupancy_combine(2,temp)
                    Occupancy_combine(:,temp) = [];
                end
                temp = temp - 1;
            end
            Idle{j,i} = Occupancy_combine;
        elseif actual_occupancy_num == 0
            Occupancy{j,i} = [0;0];
            Idle{j,i} = [0;Time_elasticity];
        end
    end
end

% for i = 1:subtask_num 
%     for j = 1:candidate_service_num
% %         Idle{j,i} = [0;Time_elasticity];
%         actual_idle_num = randi([min_occupancy_num,max_occupancy_num]); % 随机产生实际空闲时间段的段数
%         actual_time_point = randperm(Time_elasticity-1,actual_idle_num*2-1); % tmp_idle_num个空闲段需要tmp_idle_num*2-1个间隔点
%         actual_time_point_sort = [0,sort(actual_time_point),Time_elasticity];
%         k = 1;
%         if randi(2) == 1
%             while k < length(actual_time_point_sort)
%                 Idle{j,i}(1,floor(k/2)+1) = actual_time_point_sort(1,k); % 从0时刻的时间点开始，奇数时间点为空闲制造时间开始时刻
%                 Idle{j,i}(2,floor(k/2)+1) = actual_time_point_sort(1,k+1); % 从0时刻的时间点开始，偶数时间点为空闲制造时间结束时刻
%                 k = k + 2;
%             end
%         else
%             while k < length(actual_time_point_sort) - 1
%                 Idle{j,i}(1,floor(k/2)+1) = actual_time_point_sort(1,k+1); % 从0时刻的时间点开始，偶数时间点为空闲制造时间开始时刻
%                 Idle{j,i}(2,floor(k/2)+1) = actual_time_point_sort(1,k+2); % 从0时刻的时间点开始，奇数时间点为空闲制造时间结束时刻
%                 k = k + 2;
%             end
%         end
%     end
% end
end

