%% Calculating the crowding distance
% Input
%   Fitness_value：matrix of the objective function
%   Individual_front_num：front serial number of individual
%   front_num：the front_num TH front
% Output
%   distance_value：The individual crowding distance of the front_num TH front
function distance_value = crowd_distance(Fitness_value,Individual_front_num,front_num)
Population_combined_index_for_front_n = find(Individual_front_num == front_num); % Record the number of the individual on the front_num front. The length is front_num
distance_value = zeros(size(Population_combined_index_for_front_n)); % Store the individual crowding distance
Fitness_value_selected = Fitness_value(Population_combined_index_for_front_n,:); % The fitness of front_num TH front
fmax = max(Fitness_value_selected,[],1); % The maximum value in each dimension from Fitness_value_selected
fmin = min(Fitness_value_selected,[],1); % The minimum value in each dimension from Fitness_value_selected
% Calculate the crowding distance of each individual
for i = 1:size(Fitness_value,2)
    Fitness_value_i_in_front_n = Fitness_value(Population_combined_index_for_front_n,i); % The iTH target value
    [~,Fitness_value_i_in_front_n_index] = sortrows(Fitness_value_i_in_front_n); % The iTH target value is sorted in ascending order
    distance_value(Fitness_value_i_in_front_n_index(1)) = inf; % The individual distance for the minimum target value is set to infinity
    distance_value(Fitness_value_i_in_front_n_index(end)) = inf; % The individual distance for the maximum target value is set to infinity
    % Traverse from the second to the penultimate
    for j = 2:length(Population_combined_index_for_front_n)-1
        next = Population_combined_index_for_front_n(Fitness_value_i_in_front_n_index(j+1)); % Number of the next individual in Population_combined
        prev = Population_combined_index_for_front_n(Fitness_value_i_in_front_n_index(j-1)); % Number of the previous individual in Population_combined
        % Crowding distance of the jth individual in population_combined_index_for_front_n, superimposed from dimensions with different target values
        distance_value(Fitness_value_i_in_front_n_index(j)) = distance_value(Fitness_value_i_in_front_n_index(j))...
            +(Fitness_value(next,i)-Fitness_value(prev,i))...
            /(fmax(i)-fmin(i));
    end
end
end

