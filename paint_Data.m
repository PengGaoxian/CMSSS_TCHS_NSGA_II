% 功能：加载 FSGS 与 MEOS 两种调度策略在多组 QoS 权重下的实验结果，
%       绘制 Pareto 前沿散点图、能耗分段柱状图、能耗箱线图及甘特图，
%       用于论文中两种策略的对比分析。
%
% 输入：（无函数输入，脚本直接从当前目录加载 .mat 文件）
%   Data_FSGS-{postfix}.mat / Data_MEOS-{postfix}.mat — 各权重组合的实验结果文件，
%   postfix 对应权重后缀（333/550/505/055/100/010/001），
%   由 Generate the data 区块（默认注释）批量生成；单次实验结果由 Main_FSGS/Main_MEOS 生成
%
% 处理流程：
%   1. 【生成数据】（默认注释，解除注释后执行）
%      遍历 7 组权重 × 2 种策略，依次运行 Main_FSGS / Main_MEOS，
%      将输出的 .mat 文件重命名为带权重后缀的文件名
%   2. 【Pareto 前沿散点图】
%      对每组权重绘制一张图，以 QoS 综合适应度（下层）为 x 轴、
%      预热能耗（上层）为 y 轴，FSGS 用红色星号、MEOS 用蓝色菱形叠加对比
%   3. 【能耗分段柱状图】
%      将下层适应度按 [0,0.2) / [0.2,0.4) / [0.4,0.6) / [0.6,0.8) / 全体
%      五段分组，计算各段上层能耗均值，对每组权重绘制一张分组柱状图
%   4. 【能耗箱线图】
%      按同样五段 + 全体共 6 列，用 NaN 补齐为等长矩阵后绘制箱线图
%   5. 【甘特图】
%      从 Data_MEOS-333.mat 随机抽取一个 Pareto 前沿个体，
%      调用 paint_gantt 绘制服务执行与物流时段甘特图
%
% 输出：（均为图窗，不保存文件）
%   · 7 张 Pareto 前沿对比散点图（FSGS vs MEOS）
%   · 7 张能耗分段均值柱状图
%   · 7 张能耗箱线图
%   · 1 张甘特图

clear
clc

scale_configs = [10,5; 10,10; 10,15; 10,20; 5,10; 15,10; 20,10];  % [subtask_num, candidate_service_num]

% 统一配色（与 Filename 顺序一致，修改此处即可同步所有图）
algo_colors = [1.0000, 0.4980, 0;         % MOPSO       橙  (ColorBrewer Set1)
               0.5961, 0.3059, 0.6392;   % MOEA/D      紫  (ColorBrewer Set1)
               0.8941, 0.1020, 0.1098;   % NSGA-II     红  (ColorBrewer Set1)
               0.2157, 0.4941, 0.7216;   % ESGS-NSGA-II 蓝  (ColorBrewer Set1)
               0.4660, 0.6740, 0.1880;   % MEOS        绿
               0.3010, 0.7450, 0.9330;   % EOS         浅蓝
               0.3020, 0.6863, 0.2902];  % TCHS-NSGA-II 绿  (ColorBrewer Set1)

for scale_idx = 1:size(scale_configs, 1)
    subtask_num           = scale_configs(scale_idx, 1);
    candidate_service_num = scale_configs(scale_idx, 2);
    fprintf('\n===== 规模 n=%d m=%d (%d/%d) =====\n', subtask_num, candidate_service_num, scale_idx, size(scale_configs,1));

    %% 生成数据（需要重跑算法时解除注释；已有 .mat 文件时保持注释）
    dirname = [fileparts(mfilename('fullpath')), sprintf('\\outputs_n%d_m%d\\', subtask_num, candidate_service_num)];
    mkdir(dirname);
    Main_file = ["Main_FSGS";"Main_MEOS";"Main_EOS";"Main_ESGS_Forward";"Main_MOEAD";"Main_MOPSO"];
    Filename = ["Data_FSGS";"Data_MEOS";"Data_EOS";"Data_ESGS_Forward";"Data_MOEAD";"Data_MOPSO"];
    Filename_postfix = ["333";"550";"505";"055";"100";"010";"001"]; % 权重后缀，如 "333" 对应 0.34,0.33,0.33
    Weight = [0.34,0.33,0.33;0.5,0.5,0;0.5,0,0.5;0,0.5,0.5;1,0,0;0,1,0;0,0,1];

    for ii = 1:size(Filename_postfix,1)
        w_Quality = Weight(ii,1);
        w_Cost = Weight(ii,2);
        w_Time = Weight(ii,3);
        for jj = 1:size(Filename,1)
            save('weight_current','w_Quality','w_Cost','w_Time','subtask_num','candidate_service_num')
            save('parameters','Main_file','Filename','Filename_postfix','Weight','ii','jj','dirname','scale_configs','scale_idx')
            fprintf('[%s] 权重组 %d/%d  算法 %s ...\n', datestr(now,'HH:MM:SS'), ii, size(Filename_postfix,1), strtrim(Main_file(jj,:)));
            eval(Main_file(jj,:))
            load('parameters')

            file_type = ".mat";
            source_file = strcat(dirname, Filename(jj,:), file_type);
            objective_file = strcat(dirname, Filename(jj,:), "-", Filename_postfix(ii,:), file_type);

            movefile(source_file,objective_file)
        end
        %% 合并 MEOS 与 EOS 前沿，生成 TCHS 联合前沿（jj 循环结束后两者已重命名，由 Main_TCHS 从后缀文件加载）
        eval('Main_TCHS')
        file_type = ".mat";
        movefile(strcat(dirname, 'Data_TCHS', file_type), ...
                 strcat(dirname, 'Data_TCHS-', Filename_postfix(ii,:), file_type))
    end

    %% 加载数据并绘制 Pareto 前沿散点图
    dirname = [fileparts(mfilename('fullpath')), sprintf('\\outputs_n%d_m%d\\', subtask_num, candidate_service_num)];
    fig_dir = [fileparts(mfilename('fullpath')), sprintf('\\outputs_n%d_m%d\\figures\\', subtask_num, candidate_service_num)];
    csv_dir = [fileparts(mfilename('fullpath')), sprintf('\\outputs_n%d_m%d\\csv\\', subtask_num, candidate_service_num)];
    mkdir(fig_dir); mkdir(csv_dir);
    Filename = ["Data_MOPSO";"Data_MOEAD";"Data_FSGS";"Data_ESGS_Forward";"Data_MEOS";"Data_EOS";"Data_TCHS"];
    Filename_postfix = ["333";"550"u;"505";"055";"100";"010";"001"];
    marker_styles = {'s','^','*','d','o','x','o'};
    legend_names = {'MOPSO','MOEA/D','NSGA-II','ESGS-NSGA-II','MEOS','EOS','TCHS-NSGA-II'};
    plot_mask    = [true; true; true; true; false; false; true];  % 控制散点图中显示的算法

    for ii = 1:size(Filename_postfix,1)
        figure('Visible','off')
        pareto_strategy    = {};
        pareto_qos         = [];
        pareto_energy      = [];
        pareto_quality     = [];
        pareto_cost        = [];
        pareto_time        = [];
        pareto_energy_raw  = [];
        pareto_run_time    = [];
        pareto_hv          = [];
        for jj = 1:size(Filename,1)
            file = strcat(dirname,Filename(jj,:), "-", Filename_postfix(ii,:));
            Run_Time = NaN;  % TCHS 无独立运行时间，兜底为 NaN
            load(file)
            if plot_mask(jj)
                plot(QoS_Fitness, Energy_Fitness, marker_styles{jj}, 'Color', algo_colors(jj,:), 'MarkerFaceColor','none');
                hold on
            end
            title(strcat("iteration=", string(gen_max)))
            x_desc = strcat("Quality,Cost,Time", "-", Filename_postfix(ii,:));
            xlabel(x_desc),ylabel("Preheating Energy Consumption");
            n_pts = size(QoS_Fitness, 1);
            [~, fname]    = fileparts(file);
            strategy_name = strrep(fname, 'Data_', '');
            pareto_strategy   = [pareto_strategy;   repmat({strategy_name}, n_pts, 1)];
            pareto_qos        = [pareto_qos;        QoS_Fitness];
            pareto_energy     = [pareto_energy;     Energy_Fitness];
            pareto_quality    = [pareto_quality;    Quality];
            pareto_cost       = [pareto_cost;       Cost];
            pareto_time       = [pareto_time;       Time];
            pareto_energy_raw = [pareto_energy_raw; Energy_Raw];
            pareto_run_time   = [pareto_run_time;   repmat(Run_Time, n_pts, 1)];
            pareto_hv         = [pareto_hv;         repmat(HV,       n_pts, 1)];
        end
        hold off
        legend(legend_names(plot_mask), 'Location', 'best', 'Interpreter', 'none');
        postfix = char(strtrim(Filename_postfix(ii,:)));
        T_pareto = table(pareto_strategy, pareto_qos, pareto_energy, pareto_quality, pareto_cost, pareto_time, pareto_energy_raw, pareto_run_time, pareto_hv, ...
            'VariableNames', {'Strategy','QoS_Fitness','Energy_Fitness','Quality','Cost','Time','Energy_Raw','Run_Time','HV'});
        writetable(T_pareto, fullfile(csv_dir, ['pareto_data-', postfix, '.csv']));
        print(gcf, fullfile(fig_dir, ['pareto-', postfix]), '-dsvg');
        close(gcf);
    end

    %% 绘制 HV 收敛曲线
    line_styles = {'-','-','-','-','-','-','-'};
    for ii = 1:size(Filename_postfix, 1)
        postfix = char(strtrim(Filename_postfix(ii,:)));
        figure('Visible','off'); hold on;
        h = []; plotted_names = {};
        hv_conv_data = {}; hv_conv_names = {};
        for jj = 1:size(Filename, 1)
            fpath = fullfile(dirname, [char(strtrim(Filename(jj,:))), '-', postfix, '.mat']);
            if ~exist(fpath, 'file'), continue; end
            tmp = load(fpath, 'HV_history');
            if ~isfield(tmp, 'HV_history'), continue; end
            hv_conv_data{end+1} = tmp.HV_history;
            hv_conv_names{end+1} = legend_names{jj};
            if ~plot_mask(jj), continue; end
            h(end+1) = plot(tmp.HV_history, line_styles{jj}, 'Color', algo_colors(jj,:), 'LineWidth', 1);
            plotted_names{end+1} = legend_names{jj};
        end
        hold off;
        xlabel('Generation'); ylabel('Hypervolume (HV)');
        title(['HV Convergence - Weight: ', postfix]);
        if ~isempty(h)
            legend(h, plotted_names, 'Location', 'best', 'Interpreter', 'none');
        end
        print(gcf, fullfile(fig_dir, ['hv_convergence-', postfix]), '-dsvg');
        close(gcf);
        if ~isempty(hv_conv_data)
            max_len = max(cellfun(@numel, hv_conv_data));
            hv_mat = NaN(max_len, numel(hv_conv_data));
            for k = 1:numel(hv_conv_data)
                hv_mat(1:numel(hv_conv_data{k}), k) = hv_conv_data{k};
            end
            T_hv = array2table(hv_mat, 'VariableNames', hv_conv_names);
            writetable(T_hv, fullfile(csv_dir, ['hv_convergence-', postfix, '.csv']));
        end
    end

    %% 加载数据并绘制能耗分段均值柱状图

    for iii = 1:size(Filename_postfix,1)
        figure('Visible','off')
        Energy_percentage = zeros(6,size(Filename,1));
        for jjj = 1:size(Filename,1)
            file = strcat(dirname, Filename(jjj,:), "-", Filename_postfix(iii,:));
            save(fullfile(tempdir,'parameters1'),'dirname','Filename_postfix','Filename','iii','jjj','Energy_percentage','file','subtask_num','candidate_service_num','plot_mask','legend_names','fig_dir','csv_dir','scale_configs','scale_idx','algo_colors')
            clear % 清除上一轮数据
            load(fullfile(tempdir,'parameters1'))
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

            A_top_avg = mean(A_top,'all');
            B_top_avg = mean(B_top,'all');
            C_top_avg = mean(C_top,'all');
            D_top_avg = mean(D_top,'all');
            E_top_avg = mean(E_top,'all');

            K_top_avg = mean(front_Fitness_top,'all');
            Energy_percentage(:,jjj) = [A_top_avg,B_top_avg,C_top_avg,D_top_avg,E_top_avg,K_top_avg];
        end
        bh = bar(Energy_percentage(:, plot_mask));
        vis_colors = algo_colors(plot_mask, :);
        for k = 1:numel(bh), bh(k).FaceColor = vis_colors(k,:); end
        legend(legend_names(plot_mask), 'Location', 'best', 'Interpreter', 'none');
        title(Filename_postfix(iii,:))
        xticklabels({'0~0.2','0.2~0.4','0.4~0.6','0.6~0.8','0.8~1.0','total'})
        set(gcf,'unit','centimeters','position',[10 5 16 10]); % 调整图窗尺寸
        ylabels = get(gca, 'yticklabel');
        ylabels_modify = cell(size(ylabels));
        for i = 1:size(ylabels,1)
            num = 100 * str2num(ylabels{i,1});
            str = num2str(num);
            ylabels_modify{i,:} = strcat(str,'%');
        end
        set(gca,'yticklabel',ylabels_modify);
        print(gcf, fullfile(fig_dir, "energy_bar-" + strtrim(Filename_postfix(iii,:))), '-dsvg');
        close(gcf);
        col_names = cellstr(strtrim(Filename))';
        row_names = {'0~0.2','0.2~0.4','0.4~0.6','0.6~0.8','0.8~1.0','total'};
        T_bar = array2table(Energy_percentage, 'VariableNames', col_names, 'RowNames', row_names);
        writetable(T_bar, fullfile(csv_dir, "energy_bar_data-" + strtrim(Filename_postfix(iii,:)) + ".csv"), 'WriteRowNames', true);
    end

    %% 绘制甘特图
    Filename_gantt = "Data_MEOS-333";

    file = strcat(dirname,Filename_gantt);
    load(file)
    index = randi(size(Population_front,1));
    Individual = Population_front_last(index,:);
    Individual_Start_candidate_service = Population_front_last_Start_candidate_service(index,:);
    Individual_End_candidate_service = Population_front_last_End_candidate_service(index,:);
    Individual_Start_logistics = Population_front_last_Start_logistics(index,:);
    Individual_End_logistics = Population_front_last_End_logistics(index,:);
    paint_gantt(Individual,Occupancy,Time_elasticity,Individual_Start_candidate_service,Individual_End_candidate_service,Individual_Start_logistics,Individual_End_logistics)
    print(gcf, fullfile([fileparts(mfilename('fullpath')), sprintf('\\outputs_n%d_m%d\\figures\\', subtask_num, candidate_service_num)], 'gantt'), '-dsvg');
    close(gcf);

end  % scale_idx 外层循环

%% 跨规模总均值柱状图（每组权重一张，各算法值为所有规模的均值）
Filename = ["Data_MOPSO";"Data_MOEAD";"Data_FSGS";"Data_ESGS_Forward";"Data_MEOS";"Data_EOS";"Data_TCHS"];
Filename_postfix = ["333";"550";"505";"055";"100";"010";"001"];
plot_mask    = [true; true; true; true; false; false; true];
legend_names = {'MOPSO','MOEA/D','NSGA-II','ESGS-NSGA-II','MEOS','EOS','TCHS-NSGA-II'};
fig_dir_global = [fileparts(mfilename('fullpath')), '\outputs_global_bar\'];
mkdir(fig_dir_global);
for iii = 1:size(Filename_postfix,1)
    Energy_pct_sum = zeros(6, size(Filename,1));
    for scale_idx = 1:size(scale_configs,1)
        subtask_num           = scale_configs(scale_idx,1);
        candidate_service_num = scale_configs(scale_idx,2);
        dirname_g = [fileparts(mfilename('fullpath')), sprintf('\\outputs_n%d_m%d\\', subtask_num, candidate_service_num)];
        for jjj = 1:size(Filename,1)
            file = strcat(dirname_g, Filename(jjj,:), "-", Filename_postfix(iii,:));
            tmp = load(file, 'Population_front_last_Fitness_value');
            fb = tmp.Population_front_last_Fitness_value(:,2);
            ft = tmp.Population_front_last_Fitness_value(:,1);
            Energy_pct_sum(:,jjj) = Energy_pct_sum(:,jjj) + ...
                [mean(ft(fb>=0.0 & fb<0.2),'all');
                 mean(ft(fb>=0.2 & fb<0.4),'all');
                 mean(ft(fb>=0.4 & fb<0.6),'all');
                 mean(ft(fb>=0.6 & fb<0.8),'all');
                 mean(ft(fb>=0.8 & fb<1.0),'all');
                 mean(ft,'all')];
        end
    end
    Energy_pct_mean = Energy_pct_sum / size(scale_configs,1);

    figure('Visible','off')
    bh = bar(Energy_pct_mean(:, plot_mask));
    vis_colors = algo_colors(plot_mask, :);
    for k = 1:numel(bh), bh(k).FaceColor = vis_colors(k,:); end
    legend(legend_names(plot_mask), 'Location', 'best', 'Interpreter', 'none');
    title(['All Scales Mean - Weight: ', char(strtrim(Filename_postfix(iii,:)))])
    xticklabels({'0~0.2','0.2~0.4','0.4~0.6','0.6~0.8','0.8~1.0','total'})
    set(gcf,'unit','centimeters','position',[10 5 16 10]);
    ylabels = get(gca,'yticklabel');
    ylabels_modify = cell(size(ylabels));
    for i = 1:size(ylabels,1)
        ylabels_modify{i,:} = strcat(num2str(100*str2num(ylabels{i,1})),'%');
    end
    set(gca,'yticklabel',ylabels_modify);
    print(gcf, fullfile(fig_dir_global, "energy_bar_mean-" + strtrim(Filename_postfix(iii,:))), '-dsvg');
    close(gcf);
end
