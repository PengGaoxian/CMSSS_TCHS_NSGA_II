%% 通过种群的上层目标最小化和底层目标最小化寻找帕累托前沿个体
% 输入
%   Fitness_top：种群中个体的上层目标
%   Fitness_bottom：种群中个体的底层目标
% 输出
%   Individual_front：种群中的帕累托前沿个体
function [Individual_front_num] = pareto_front(Fitness_value)
Fitness_top = Fitness_value(:,1);
Fitness_bottom = Fitness_value(:,2);
population_size = size(Fitness_value,1);
Individual_front_num = zeros(population_size,1);
Individual_label = false(population_size,1);
front_num = 0;
while ~all(Individual_label)
    label_index = []; % 存放前沿个体的序号
    front_num = front_num + 1;
    % 遍历种群中的个体
    for i = 1:population_size
        % 如果个体没有被标记
        if ~Individual_label(i)
            dominate_num = 0; % 记录支配第i个个体的数目
            % 遍历种群中的个体
            for j = 1:population_size
                % 如果个体没有被标记
                if ~Individual_label(j)
                    % 如果不是同一个个体
                    if i ~= j
                        if ((Fitness_top(j,1)<Fitness_top(i,1) && Fitness_bottom(j,1)<Fitness_bottom(i,1)))
                            dominate_num = dominate_num + 1;
                        elseif ((Fitness_top(j,1)==Fitness_top(i,1) && Fitness_bottom(j,1)<Fitness_bottom(i,1)))
                            dominate_num = dominate_num + 1;
                        elseif ((Fitness_top(j,1)<Fitness_top(i,1) && Fitness_bottom(j,1)==Fitness_bottom(i,1)))
                            dominate_num = dominate_num + 1;
                        end
                    end
                end
            end
            if dominate_num == 0 % 支配第i个个体的数目为0，则为i前沿个体
                Individual_front_num(i) = front_num;
                current = numel(label_index)+1;
                label_index(current,1) = i;
            end
        end
    end
    Individual_label(label_index,1) = true;
end
end

