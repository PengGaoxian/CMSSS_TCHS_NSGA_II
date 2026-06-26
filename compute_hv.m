% 功能：计算二维帕累托前沿的超体积指标（HV）。
%
% 输入：
%   pareto_front — [n × 2] 帕累托前沿点集，每行为一个解的两个目标值（最小化）
%                  第 1 列为第一目标（Energy），第 2 列为第二目标（QoS）
%   ref_point    — [1 × 2] 参考点，取各目标归一化上界略大值（论文取 [1.1, 1.1]）
%
% 处理流程：
%   1. 过滤掉任一目标值 ≥ 参考点的解（含 Inf）
%   2. 按第一目标升序排列（帕累托前沿上第二目标随之降序）
%   3. 对每个点计算其对应竖条面积并累加：
%      width  = 下一点的第一目标值 − 当前点的第一目标值（最后一点到参考点）
%      height = 参考点第二目标值   − 当前点的第二目标值
%
% 输出：
%   hv — 标量，帕累托前沿支配区域面积
function hv = compute_hv(pareto_front, ref_point)
valid = pareto_front(:,1) < ref_point(1) & pareto_front(:,2) < ref_point(2);
pts   = sortrows(pareto_front(valid, :), 1);

if isempty(pts)
    hv = 0;
    return;
end

n  = size(pts, 1);
x_next = [pts(2:end, 1); ref_point(1)];
hv = sum((x_next - pts(:,1)) .* (ref_point(2) - pts(:,2)));
end
