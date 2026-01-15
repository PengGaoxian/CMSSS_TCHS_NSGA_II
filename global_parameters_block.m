%% User perferences
ordertime = 60;
Time_required_max = 800;
Cost_required_max = 7000;
Quality_required_min = 0.6;
w_Quality = 0.34;
w_Cost = 0.33;
w_Time = 0.33;

%% Platform parameters
T_unit_dist = 0.1;
C_unit_dist = 0.1;
elastic_coefficient = 1.2;
Time_elasticity = Time_required_max*elastic_coefficient;

%% extract data from simulationData.xlsx
file_path = [pwd, '\SimulationDataset\simulationData52.xlsx'];
sheet = 'Sheet1';
range = 'A2:K51';
[subtask_num,candidate_service_num,Q,Ts,Cs,Th,Tc,Eh,Idle,P] = data_extract(file_path, sheet, range);
[Occupancy] = get_occupancy(Idle,Time_elasticity);

%% Set algorithm parameters
population_size = 50;
selection_size = 20;
gen_max = 10000;
cross_probability = 0.9; % 交叉概率
mutation_probability = 0.05; % 变异概率

%% Generating distance matrix(candidate_service_num,subtask_num)，each element in the matrix is the distance matrix between the current position and the next position
Distance_cell = cell(candidate_service_num,subtask_num); % The distance matrix, where each element of the matrix is an array, corresponds to the distance from the next location
for i = 1:subtask_num-1
    for j = 1:candidate_service_num
        Distance = zeros(candidate_service_num,1); % Defines the distance matrix between the current location and the next location
        current_position = P{j,i}; % current location
        for next_j = 1:candidate_service_num
            next_position = P{next_j,i+1}; % There are n choices for the next position
            Distance(next_j,1) = pdist([current_position;next_position]);
        end
        Distance_cell{j,i} = Distance;
    end
end
%% Find the minimum shipping time and shipping cost to calculate "Time_min" and "Cost_min"
total_min_dist = 0;
for i = 1:subtask_num-1
    min_dist = Inf;
    for j = 1:candidate_service_num
        min_dist = min([min_dist;Distance_cell{j,i}]);
    end
    total_min_dist = total_min_dist + min_dist;
end
total_min_Tl = total_min_dist * T_unit_dist;
total_min_Cl = total_min_dist * C_unit_dist;

%% Composite service parameters (regardless of optimal values for logistics and waiting times)
Quality_max = sum(max(Q,[],1))/subtask_num; 
Time_min = sum(min(Ts,[],1)) + total_min_Tl; 
Cost_min = sum(min(Cs,[],1)) + total_min_Cl; 
Energy_max = sum(max(Eh,[],1))*2;

