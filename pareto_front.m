% 功能：对种群执行非支配排序，为每个个体分配 Pareto 层级编号（front_num）。
%       层级越小（第 1 层）表示越优，第 1 层即当前种群的 Pareto 最优前沿。
%
% 输入：
%   Fitness_value - 目标值矩阵 [population_size × 2]，
%                   第 1 列为上层适应度（能耗，越小越好），
%                   第 2 列为下层适应度（QoS，越小越好，Inf 表示不可行解）
%
% 处理流程：
%   采用逐层剥离算法：
%   1. 初始化标记数组 Individual_label（false = 尚未分层）
%   2. 每轮从未标记个体中找出当前非支配集：
%      对个体 i，遍历所有未标记个体 j，若存在 j 在两个目标上均不劣于 i
%      且至少一个目标严格优于 i（严格支配），则 i 的被支配计数 +1；
%      被支配计数为 0 的个体归入当前层
%   3. 将本轮找到的非支配个体标记为已分层，front_num +1，进入下一轮
%   4. 直到所有个体均已分层
%
% 输出：
%   Individual_front_num - 层级编号列向量 [population_size × 1]，
%                          值为 1 表示第一 Pareto 前沿（最优），数值越大越差
function [Individual_front_num] = pareto_front(Fitness_value)
Fitness_top = Fitness_value(:,1);
Fitness_bottom = Fitness_value(:,2);
population_size = size(Fitness_value,1);
Individual_front_num = zeros(population_size,1);
Individual_label = false(population_size,1);
front_num = 0;
while ~all(Individual_label)
    label_index = []; % 存放前沿个体的序号
    front_num = front_num + 1;
    % 遍历种群中的个体
    for i = 1:population_size
        % 如果个体没有被标记
        if ~Individual_label(i)
            dominate_num = 0; % 记录支配第i个个体的数目
            % 遍历种群中的个体
            for j = 1:population_size
                % 如果个体没有被标记
                if ~Individual_label(j)
                    % 如果不是同一个个体
                    if i ~= j
                        if ((Fitness_top(j,1)<Fitness_top(i,1) && Fitness_bottom(j,1)<Fitness_bottom(i,1)))
                            dominate_num = dominate_num + 1;
                        elseif ((Fitness_top(j,1)==Fitness_top(i,1) && Fitness_bottom(j,1)<Fitness_bottom(i,1)))
                            dominate_num = dominate_num + 1;
                        elseif ((Fitness_top(j,1)<Fitness_top(i,1) && Fitness_bottom(j,1)==Fitness_bottom(i,1)))
                            dominate_num = dominate_num + 1;
                        end
                    end
                end
            end
            if dominate_num == 0 % 支配第i个个体的数目为0，则为i前沿个体
                Individual_front_num(i) = front_num;
                current = numel(label_index)+1;
                label_index(current,1) = i;
            end
        end
    end
    Individual_label(label_index,1) = true;
end
end

