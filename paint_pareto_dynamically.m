% 功能：动态展示 NSGA-II 迭代过程中 Pareto 前沿的演化过程，
%       逐代刷新散点图，直观呈现种群目标值分布随迭代收敛的变化趋势。
%
% 输入：
%   Populations_front_num      - 历代前沿编号 cell [gen_max × 1]，
%                                每元素为列向量，存储该代每个个体所属的 Pareto 层级编号
%   Populations_Fitness_value  - 历代目标值 cell [gen_max × 1]，
%                                每元素为 [population_size × 2] 矩阵，
%                                第1列为上层适应度（能耗），第2列为下层适应度（QoS）
%   gen_max                    - 总迭代代数
%
% 处理流程：
%   逐代（n = 1 → gen_max）执行：
%   1. 取出第 n 代的前沿编号与目标值
%   2. 计算本代最大前沿层级 max_front_num
%   3. 从外层（max_front_num）到第 1 层逆序绘制，
%      使第 1 层（最优前沿）覆盖在最上层，显示效果最佳
%   4. 更新标题为当前代数与前沿层数，暂停 0.05 秒后刷新
%
% 输出：（动态图窗，不保存文件）
%   实时更新的 Pareto 前沿散点图：x 轴为能耗适应度，y 轴为 QoS 适应度，
%   不同前沿层级用不同颜色的圆点区分
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

