%% 变异
% 输入
%   Selection：被选种群
%   mutation_probability：变异概率
% 输出
%   Population_mutated：变异后的种群
function [Population_mutated] = mutate(Population,mutation_probability,candidate_service_num)
Population_mutated = Population;
[population_size,subtask_num] = size(Population);
for i = 1:population_size
    if rand <= mutation_probability
        Section = randi(subtask_num,1,2); % 产生变异区间
        start_point = Section(1,1);
        end_point = Section(1,2);
        if start_point <= end_point
            Section_temp = randi(candidate_service_num,1,end_point-start_point+1);
            Population_mutated(i,start_point:end_point) = Section_temp;
        else
            Section_temp_back = randi(candidate_service_num,1,subtask_num-start_point+1);
            Population_mutated(i,start_point:subtask_num) = Section_temp_back;
            Section_temp_front = randi(candidate_service_num,1,end_point);
            Population_mutated(i,1:end_point) = Section_temp_front;
        end
    end
end
end

