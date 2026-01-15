%% 获取下一代Population在Population_combined中的序号index
% 输入
%   Fitness_value：组合种群的适应度值
%   front_num：组合种群的前沿编号
%   population_size：种群大小
% 输出
%   index：选出的Population中的个体在Population_combined中的序号
function [Population_index,front_index] = select_population(Fitness_value,front_num,population_size)
    Population_index = zeros(population_size,1);
    front_index = find(front_num==1);
    front_num_ge = 1;
    % 判断前front_num个前沿个体复制到下一代
    while true
        nums_ge_population_size = numel(front_num,front_num<=front_num_ge); % 计算前front_index个前沿中的个体数量
        if nums_ge_population_size >= population_size
            break;
        end
        front_num_ge = front_num_ge + 1;
    end
    if nums_ge_population_size > population_size
        front_num_lt = front_num_ge - 1;
        nums_lt_population_size = numel(front_num,front_num<=front_num_lt);
        % 获取Population的个体在Population_combined种群中的序号(前front_num个前沿)
        Population_index(1:nums_lt_population_size,1) = find(front_num<=front_num_lt);
        % 补充种群
        Population_combined_index_for_front_n = find(front_num == front_num_ge); % 记录第front_num_ge个前沿的个体编号
        distance_value = crowd_distance(Fitness_value,front_num,front_num_ge); % 计算拥挤距离
        combine_distance_index_for_front_n = [distance_value';Population_combined_index_for_front_n']'; % 合并距离和序号
        Population_combined_index_for_front_n = sortrows(combine_distance_index_for_front_n,'descend'); % 按拥挤距离降序排列第front_num个前沿上的个体
        population_vacancy_size = population_size - nums_lt_population_size; % 种群中缺少的个体数量
        Population_filled_index = Population_combined_index_for_front_n(1:population_vacancy_size,2); % 填补种群的个体
        % 补充Population中空缺的序号，序号从Population_combined中获得
        Population_index(nums_lt_population_size+1:population_size,1) = Population_filled_index; 
    elseif nums_ge_population_size == population_size
        % 获取Population的个体在Population_combined种群中的序号
        Population_index = find(front_num<=front_num_ge);
    end
end

