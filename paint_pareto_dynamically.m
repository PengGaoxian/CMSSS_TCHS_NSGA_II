%% 画出pareto前沿
% 输入
%   Populations_front_num：gen_max代种群的前沿编号
%   Populations_Fitness_value：gen_max代种群的目标值
%   gen_max：迭代次数
function [] = paint_pareto_dynamically(Populations_front_num,Populations_Fitness_value,gen_max)
figure;
for n = 1:gen_max
    Population_front_num = Populations_front_num{n,1}; % 取出种群的前沿编号
    Population_Fitness_value = Populations_Fitness_value{n,1}; % 取出种群的目标值
    
    max_front_num = max(Population_front_num(:,1)); % 计算种群的最大前沿编号
    plot(0,0);
    for m = max_front_num:-1:1 % 越前沿，越后画，越上层，显示效果越好
        Fitness_value_for_front_m = Population_Fitness_value(Population_front_num==m,:);
%         axis([0 1 0 1]);
        plot(Fitness_value_for_front_m(:,1),Fitness_value_for_front_m(:,2),'o');
        tt = sprintf('gen: %d, front num: %d',n,max_front_num);
        title(tt);
        xlabel('Energy-saving'),ylabel('Time、Cost、Quality'); %x、y轴的名称
        hold on
    end
    hold off
    pause(0.05);
end
end

