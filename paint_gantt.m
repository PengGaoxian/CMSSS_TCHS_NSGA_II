% 功能：为云制造服务组合调度方案绘制甘特图，
%       在同一时间轴上展示每个子任务的服务占用时段（灰色）、
%       服务执行时段（绿色）和相邻子任务间的物流时段（蓝色）。
%
% 输入：
%   Individual                          - 个体行向量 [1 × subtask_num]，
%                                         每个元素为对应子任务所选候选服务的序号
%   Occupancy                           - 占用时段 cell [candidate_service_num × subtask_num]，
%                                         每元素为 2×m 矩阵（第1行=占用开始，第2行=占用结束）
%   Time_elasticity                     - 时间轴上界（deadline × elastic_coefficient）
%   Individual_Start_candidate_service  - 服务执行开始时间行向量 [1 × subtask_num]
%   Individual_End_candidate_service    - 服务执行结束时间行向量 [1 × subtask_num]
%   Individual_Start_logistic           - 物流开始时间行向量 [1 × subtask_num]
%   Individual_End_logistic             - 物流结束时间行向量 [1 × subtask_num]
%
% 处理流程：
%   对每个子任务 i（y 轴坐标为 i）：
%   1. 从 Occupancy{服务序号, i} 取出所有占用时段，逐段绘制灰色矩形
%   2. 绘制绿色矩形表示该子任务的服务执行时段，并标注子任务序号
%   3. 若不是最后一个子任务，绘制蓝色矩形表示到下一子任务的物流时段，
%      并标注"当前服务序号.下一服务序号"格式的文本
%   完成后设置坐标轴范围、刻度、标签和图窗尺寸
%
% 输出：（图窗，不保存文件）
%   甘特图：x 轴为时间，y 轴为子任务编号，三色区块直观展示调度方案时序结构
function [] = paint_gantt(Individual,Occupancy,Time_elasticity,Individual_Start_candidate_service,Individual_End_candidate_service,Individual_Start_logistic,Individual_End_logistic)
[~,subtask_num] = size(Individual);
figure;
for i = 1:subtask_num
    candidate_service_index = Individual(1,i);
    Occupancy_combine = Occupancy{candidate_service_index,i};
    [~,col] = size(Occupancy_combine);
    %% 画图描述占用时间
    for l = 1:col
        rec(1) = Occupancy_combine(1,l); % 矩形的横坐标,即工序的开始时间
%         rec(2) = i*2-1-0.2; % 矩形左下角的纵坐标，奇数坐标
        rec(2) = i-0.2; % 矩形左下角的纵坐标，奇数坐标
        rec(3) = Occupancy_combine(2,l) - Occupancy_combine(1,l); % 矩形的长度，即加工时间
        rec(4) = 0.4; % 矩形的高度
%         txt = sprintf('%d',l); % 占用时间段的序号
        % 画矩形
        rectangle('Position',rec,'LineWidth',0.5,'LineStyle','-','FaceColor',[0.8,0.8,0.8]);
        % 确定文本位置
%         text(rec(1),rec(2)+0.5,txt,'FontSize',8);
    end
    %% 画图描述服务时间
    rec(1) = Individual_Start_candidate_service(1,i);
%     rec(2) = i*2-1-0.2;
    rec(2) = i-0.2;
    rec(3) = Individual_End_candidate_service(1,i)-Individual_Start_candidate_service(1,i);
    rec(4) = 0.4;
    rectangle('Position',rec,'LineWidth',0.5,'LineStyle','-','FaceColor','green'); % 画矩形
    txt = sprintf('%d',i); % 文本描述
    text(rec(1),rec(2)+0.5,txt,'FontSize',8); % 文本位置
    %% 画图描述物流时间
    if i < subtask_num
        rec(1) = Individual_Start_logistic(1,i);
%         rec(2) = i*2-0.2;
        rec(2) = i+0.2;
        rec(3) = Individual_End_logistic(1,i)-Individual_Start_logistic(1,i);
        rec(4) = 0.4;
        rectangle('Position',rec,'LineWidth',0.5,'LineStyle','-','FaceColor','blue'); % 画矩形
    
        txt = sprintf('%d.%d-%d.%d',i,Individual(i),i+1,Individual(i+1)); % 物流文本描述
    end
    text(rec(1),rec(2)+0.5,txt,'FontSize',8); % 文本位置
end
Y = subtask_num;
axis([0,Time_elasticity,0,Y+1]); %x、y轴的范围
set(gca,'xtick',0:20:Time_elasticity,'ytick',0:Y); %x、y轴的增长幅度
xlabel('Time'),ylabel('candidate service index'); %x、y轴的名称
set(gca,'Fontsize',8,'xgrid','on','LooseInset',get(gca,'TightInset')); % 去除图片白边
set(gcf,'unit','centimeters','position',[10 5 20 8]);   %调整图片大小
% 保存图片
% currPath = fileparts(mfilename('fullpath'));
% print(gcf,'-djpeg','-r300',[currPath,'\甘特图']);
end

