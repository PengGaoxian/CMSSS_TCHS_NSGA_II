function [] = paint_occupancy(Occupancy,Time_elasticity,title_text)
[candidate_service_num,subtask_num] = size(Occupancy);
for i = 1:subtask_num
    for j = 1:candidate_service_num
        Occupancy_combine = Occupancy{j,i};
        index = (i-1)*candidate_service_num+j;
        [~,col] = size(Occupancy_combine);
        for k = 1:col
            rec(1) = Occupancy_combine(1,k); % 矩形的横坐标,即工序的开始时间
            rec(2) = index-0.2; % 矩形左下角的纵坐标，即机器号
            rec(3) = Occupancy_combine(2,k) - Occupancy_combine(1,k); % 矩形的长度，即加工时间
            rec(4) = 0.4; % 矩形的高度
            txt = sprintf('%d',k); % 占用时间段的序号
            % 画矩形
            rectangle('Position',rec,'LineWidth',0.5,'LineStyle','-','FaceColor',[0.8,0.8,0.8]);
            % 确定文本位置
            text(rec(1),rec(2)+0.5,txt,'FontSize',8);
        end
    end
end
Y = candidate_service_num*subtask_num;
axis([0,Time_elasticity,0,Y+1]); %x、y轴的范围
set(gca,'xtick',0:10:Time_elasticity,'ytick',0:Y); %x、y轴的增长幅度
xlabel('Time'),ylabel('candidate service index'); %x、y轴的名称
set(gca,'Fontsize',8,'xgrid','on','LooseInset',get(gca,'TightInset')); % 去除图片白边
set(gcf,'unit','centimeters','position',[10 5 10 6]);   %调整图片大小
title(title_text)
% 保存图片
% currPath = fileparts(mfilename('fullpath'));
% print(gcf,'-djpeg','-r300',[currPath,'\',title_text]);
end

