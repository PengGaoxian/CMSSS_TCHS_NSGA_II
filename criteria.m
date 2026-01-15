%% Obtain the completion quality, completion cost and completion time of each individual in the population.
% Input
%   Population：population of cloud manufacturing service
%   Q：Candidate quality of service dataset
%   Cs：Candidate service cost dataset
%   End_candidate_service：The subtask completion time dataset for the candidate service
% Output
%   Quality：Quality required to complete the task
%   Cost：Cost required to complete the task
%   Time：Time required to complete the task
function [Quality,Cost,Time] = criteria(Population,Q,Cs,End_candidate_service,Cl)
[population_size,subtask_num] = size(Population);

total_Q = zeros(population_size,1);
total_Cs = zeros(population_size,1);
total_Cl = zeros(population_size,1);
total_T = zeros(population_size,1);
for k = 1:population_size
    for i = 1:subtask_num
        candidate_service_index = Population(k,i);
        total_Q(k,1) = total_Q(k,1) + Q(candidate_service_index,i);
        total_Cs(k,1) = total_Cs(k,1) + Cs(candidate_service_index,i);
    end
    total_Cl(k,1) = sum(Cl(k,:));
    total_T(k,1) = End_candidate_service(k,end);
end

Quality = total_Q/subtask_num;
Cost = total_Cs + total_Cl;
Time = total_T;
end