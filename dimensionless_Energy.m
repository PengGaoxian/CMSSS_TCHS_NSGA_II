%% Dimensionless energy savings for individuals
% Input
%   Energy：Actual energy consumption of candidate services preheating
%   Energy_max：The maximun preheating energy of candidate service 
% Output
%   Energy_dimensionless：The dimensionless energy consumption of each individual in the population
function [Energy_dimensionless] = dimensionless_Energy(Energy,Energy_max)
Energy_dimensionless = Energy/Energy_max;
end

