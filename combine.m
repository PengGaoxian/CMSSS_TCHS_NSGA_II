%% Merge original population, crossed population, mutated population. then remove the duplicated individuals
% Input
%   Population：original population 
%   Population_crossed：crossed population
%   Population_mutated：mutated population
% Output
%   Population_combine：the population after merged original population, crossed population, mutated population.
function [Population_combined] = combine(Population,Population_crossed,Population_mutated)
population_size = size(Population,1);
Population_combined = [Population;Population_crossed;Population_mutated];
% Remove duplicated individuals in merged population.
Population_combined = unique(Population_combined,'rows','stable');
% Size of population after removing duplicated individuals.
actual_population_size = size(Population_combined,1);
% Count the number of population vacancies.
vacancy_size = population_size - actual_population_size;
% Randomly select individuals from the population to fill the gaps.
if vacancy_size > 0
    Individual_selected_index = randi(actual_population_size,vacancy_size,1);
    Individual_selected = Population_combined(Individual_selected_index,:);
    Population_combined = [Population_combined;Individual_selected];
end
end

