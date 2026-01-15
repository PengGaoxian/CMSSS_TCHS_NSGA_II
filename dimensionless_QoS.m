%% QoS dimensionless
% Input
%   Quality：Quality required to complete Task
%   Cost：Cost required to complete Task
%   Time：Time required to complete task
%   deadline：The latest delivery time requested by the user
%   budget：Total task cost budget for the user
%   Quality_required_min：The minimum quality of total task required by the user
% Output
%   Quality_dimensionless：Dimensionless dataset of task quality
%   Cost_dimensionless：Dimensionless dataset of task cost
%   Time_dimensionless：Dimensionless dataset of task Time
function [Quality_dimensionless,Cost_dimensionless,Time_dimensionless] = dimensionless_QoS(Quality,Cost,Time,Time_required_max,Cost_required_max,Quality_required_min,Time_min,Cost_min,Quality_max)
%% Normalization and dimensionless processing of Quality
Quality_dimensionless = (Quality_max - Quality)/(Quality_max - Quality_required_min); % If it exceeds 1, it cannot meet the customer's requirements
%% Normalization and dimensionless processing of Time
Time_dimensionless = (Time-Time_min)/(Time_required_max-Time_min); % If it exceeds 1, it cannot meet the customer's requirements
%% Normalization and dimensionless processing of Cost
Cost_dimensionless = (Cost-Cost_min)/(Cost_required_max-Cost_min); % If it exceeds 1, it cannot meet the customer's requirements