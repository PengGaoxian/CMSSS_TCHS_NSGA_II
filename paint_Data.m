% Main function to generate a schema for cloud manufacturing service selection and scheduling with FSGS and ESGS methods
clear
clc
global_parameters_block % Get code block of global parameters 

%% Generate the data
% Main_file = ["Main_FSGS";"Main_ESGS"];
% Filename = ["Data_FSGS";"Data_ESGS"];
% Filename_postfix = ["333";"550";"505";"055";"100";"010";"001"]; % corresponds to Weight, for example, "333" corresponds to 0.34,0.33,0.33
% Weight = [0.34,0.33,0.33;0.5,0.5,0;0.5,0,0.5;0,0.5,0.5;1,0,0;0,1,0;0,0,1];
% 
% for ii = 1:size(Filename_postfix,1)
%     w_Quality = Weight(ii,1);
%     w_Cost = Weight(ii,2);
%     w_Time = Weight(ii,3);
%     for jj = 1:size(Filename,1)
%         save('weight_current','w_Quality','w_Cost','w_Time')
%         save('parameters','Main_file','Filename','Filename_postfix','Weight','ii','jj')
%         eval(Main_file(jj,:))
%         load('parameters')
% 
%         file_type = ".mat";
%         source_file = strcat(Filename(jj,:), file_type);
%         objective_file = strcat(Filename(jj,:), "-", Filename_postfix(ii,:), file_type);
%         
%         movefile(source_file,objective_file)
%     end
% end

%% Load the generated data and plot pareto front
dirname = [pwd, '\'];
Filename = ["Data_FSGS";"Data_ESGS"];
Filename_postfix = ["333";"550";"505";"055";"100";"010";"001"];
color = ["r*";"bd"];

for ii = 1:size(Filename_postfix,1)
    figure
    for jj = 1:size(Filename,1)
        file = strcat(dirname,Filename(jj,:), "-", Filename_postfix(ii,:));
        load(file)
        plot(Population_front_last_Fitness_value(:,2),Population_front_last_Fitness_value(:,1),color(jj,:));
        hold on
        title(strcat("iteration=", string(gen_max)))
        x_desc = strcat("Quality,Cost,Time", "-", Filename_postfix(ii,:));
        xlabel(x_desc),ylabel("Preheating Energy Consumption");
    end
    hold off
end

%% Load the generated data and plot the energy consumption comparison bar chart
dirname = [pwd, '\'];
Filename = ["Data_FSGS";"Data_ESGS"];
Filename_postfix = ['333';'550';'505';'055';'100';'010';'001'];

for iii = 1:size(Filename_postfix,1)
    figure
%     Energy_percentage = zeros(6,size(Filename,1));
    Energy_percentage = zeros(5,size(Filename,1));
    for jjj = 1:size(Filename,1)
        file = strcat(dirname, Filename(jjj,:), "-", Filename_postfix(iii,:)); 
        save('parameters1','dirname','Filename_postfix','Filename','iii','jjj','Energy_percentage','file')
        clear % Clear the data of the previous round
        load('parameters1')
        load(file);
        front_Fitness_bottom = Population_front_last_Fitness_value(:,2);
        front_Fitness_top = Population_front_last_Fitness_value(:,1);
        
        A_index = find(front_Fitness_bottom>=0.0&front_Fitness_bottom<0.2);
        B_index = find(front_Fitness_bottom>=0.2&front_Fitness_bottom<0.4);
        C_index = find(front_Fitness_bottom>=0.4&front_Fitness_bottom<0.6);
        D_index = find(front_Fitness_bottom>=0.6&front_Fitness_bottom<0.8);
        E_index = find(front_Fitness_bottom>=0.8&front_Fitness_bottom<1.0);

        A_top = front_Fitness_top(A_index);
        B_top = front_Fitness_top(B_index);
        C_top = front_Fitness_top(C_index);
        D_top = front_Fitness_top(D_index);
%         E_top = front_Fitness_top(E_index);

        A_top_avg = mean(A_top,'all');
        B_top_avg = mean(B_top,'all');
        C_top_avg = mean(C_top,'all');
        D_top_avg = mean(D_top,'all');
%         E_top_avg = mean(E_top,'all');

        K_top_avg = mean(front_Fitness_top,'all');
%         Energy_percentage(:,jjj) = [A_top_avg,B_top_avg,C_top_avg,D_top_avg,E_top_avg,K_top_avg];
        Energy_percentage(:,jjj) = [A_top_avg,B_top_avg,C_top_avg,D_top_avg,K_top_avg];
    end
    bar(Energy_percentage)
    title(Filename_postfix(iii,:))
%     xticklabels({'0~0.2','0.2~0.4','0.4~0.6','0.6~0.8','0.8~1','total'})
    xticklabels({'0~0.2','0.2~0.4','0.4~0.6','0.6~0.8','total'})
    yticks([0,0.1,0.2,0.3,0.4,0.5,0.6,0.7])
    ylim([0,0.7])
    set(gcf,'unit','centimeters','position',[10 5 16 10]);   %Resize the image
    ylabels = get(gca, 'yticklabel');
    ylabels_modify = cell(size(ylabels));
    for i = 1:size(ylabels,1)
        num = 100 * str2num(ylabels{i,1});
        str = num2str(num);
        ylabels_modify{i,:} = strcat(str,'%');
    end
    set(gca,'yticklabel',ylabels_modify);
end

%% Load the generated data and plot the energy consumption comparison boxplots
dirname = [pwd, '\'];
Filename = ["Data_FSGS";"Data_ESGS"];
Filename_postfix = ['333';'550';'505';'055';'100';'010';'001'];

for iii = 1:size(Filename_postfix,1)
    figure
    Energy_percentage = zeros(6,size(Filename,1));
    for jjj = 1:size(Filename,1)
        file = strcat(dirname, Filename(jjj,:), "-", Filename_postfix(iii,:)); 
        save('parameters1','dirname','Filename_postfix','Filename','iii','jjj','Energy_percentage','file')
        clear % Clear the data of the previous round
        load('parameters1')
        load(file);
        front_Fitness_bottom = Population_front_last_Fitness_value(:,2);
        front_Fitness_top = Population_front_last_Fitness_value(:,1);
        
        A_index = find(front_Fitness_bottom>=0.0&front_Fitness_bottom<0.2);
        B_index = find(front_Fitness_bottom>=0.2&front_Fitness_bottom<0.4);
        C_index = find(front_Fitness_bottom>=0.4&front_Fitness_bottom<0.6);
        D_index = find(front_Fitness_bottom>=0.6&front_Fitness_bottom<0.8);
        E_index = find(front_Fitness_bottom>=0.8&front_Fitness_bottom<1.0);

        A_top = front_Fitness_top(A_index);
        B_top = front_Fitness_top(B_index);
        C_top = front_Fitness_top(C_index);
        D_top = front_Fitness_top(D_index);
        E_top = front_Fitness_top(E_index);
        Total_top = front_Fitness_top;
    end
    Energy_padding = NaN(population_size,6);
    
    Energy_padding(1:size(A_top,1),1) = A_top;
    Energy_padding(1:size(B_top,1),2) = B_top;
    Energy_padding(1:size(C_top,1),3) = C_top;
    Energy_padding(1:size(D_top,1),4) = D_top;
    Energy_padding(1:size(E_top,1),5) = E_top;
    Energy_padding(1:size(Total_top,1),6) = Total_top;
    
    boxplot(Energy_padding)
end

%% Plot the gantt chart
dirname = [pwd, '\'];
Filename_gantt = "Data_ESGS-333";  

file = strcat(dirname,Filename_gantt);
load(file)
index = randi(size(Population_front,1));
Individual = Population_front_last(index,:);
Individual_Start_candidate_service = Population_front_last_Start_candidate_service(index,:);
Individual_End_candidate_service = Population_front_last_End_candidate_service(index,:);
Individual_Start_logistics = Population_front_last_Start_logistics(index,:);
Individual_End_logistics = Population_front_last_End_logistics(index,:);
paint_gantt(Individual,Occupancy,Time_elasticity,Individual_Start_candidate_service,Individual_End_candidate_service,Individual_Start_logistics,Individual_End_logistics)

