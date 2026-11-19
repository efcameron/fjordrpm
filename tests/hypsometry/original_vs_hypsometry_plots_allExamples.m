% original_vs_hypsometry_plots_allExamples.m - end-of-run profiles for the original examples
% Figure A: original code vs new code (sill at mouth)
% Figure B: new code at Gsill = 60, 30, 15 km (from stage4_examples.mat)
clear; close all;
orig   = 'C:/Users/efc4/Documents/MATLAB/fjordrpm_orig';
new    = 'C:/Users/efc4/Documents/MATLAB/fjordrpm';
rundir = 'C:/Users/efc4/Documents/MATLAB/fjordrpm_runs/results/';
figdir = 'C:/Users/efc4/Documents/MATLAB/fjordrpm_runs/figures/';
warning('off','MATLAB:rmpath:DirNotFound');

exnames  = {'ex1','ex2','ex3','ex3_sill','ex4','ex5','ex6'};
extitles = {'1 discharge','2 intermediary','3 icebergs, no sill','3 icebergs + sill','4 combined','5 rivers','6 surface heat'};
exsetup  = {'setup_ex1','setup_ex2','setup_ex3','setup_ex3','setup_ex4','setup_ex5','setup_ex6'};
exsillon = [0 0 0 1 0 0 0];
vars = {'S','T'}; xl = {'Salinity','Temperature (^oC)'};

%% Part 1: rerun original and new code (sill at the mouth), keep final profiles
AL = struct();
for ie = 1:numel(exnames)
    for ic = 1:2                                   % 1 = original, 2 = new
        rmpath(genpath(new)); rmpath(genpath(orig));
        if ic == 1, addpath(genpath(orig)); else, addpath(genpath(new)); end
        clear functions
        clearvars -except orig new rundir figdir exnames extitles exsetup exsillon vars xl AL ie ic
        eval(exsetup{ie}); if exsillon(ie), p.sill = 1; end
        s = run_model(p, t, f, a);
        fprintf('%s, pass %d (1 = original, 2 = new): run_model = %s;  output has Llay field: %d\n', ...
            exnames{ie}, ic, which('run_model'), isfield(s,'Llay'));
        AL.(exnames{ie}).S(:,ic) = s.S(:,end);
        AL.(exnames{ie}).T(:,ic) = s.T(:,end);
        AL.(exnames{ie}).Ss = s.Ss(:,end);   % shelf salinity on fjord layers, final day
        AL.(exnames{ie}).Ts = s.Ts(:,end);   % shelf temperature on fjord layers, final day
        AL.(exnames{ie}).z = -abs(s.z(:));
        AL.(exnames{ie}).tend = s.t(end);
        AL.(exnames{ie}).Hsill = p.Hsill*p.sill;   % 0 if no sill
    end
end
rmpath(genpath(orig)); addpath(genpath(new)); clear functions
save([rundir 'stage4_alignment.mat'], 'AL');

%% Figure A: original vs new
figure('Position',[20 50 1800 700]);
tl = tiledlayout(2, numel(exnames), 'TileSpacing','compact');
title(tl, 'Original FjordRPM vs new code with the sill at the mouth: profiles at the end of each run');
for v = 1:2
    for ie = 1:numel(exnames)
        A = AL.(exnames{ie});
        nexttile((v-1)*numel(exnames) + ie); hold on; box on
        plot(A.([vars{v} 's']), A.z, '--', 'Color',[0.6 0.6 0.6], 'LineWidth',1.5);   % shelf
        plot(A.(vars{v})(:,1), A.z, '-',  'Color',[0 0.45 0.74],   'LineWidth',3);
        plot(A.(vars{v})(:,2), A.z, '--', 'Color',[0.85 0.33 0.1], 'LineWidth',1.5);
        if A.Hsill > 0, yline(-A.Hsill, 'k:'); end
        xlabel(xl{v});
        if v == 1, title({extitles{ie}, sprintf('day %g', A.tend)}); end
        if ie == 1, ylabel('Depth (m)'); end
        if v == 1 && ie == 1, legend('Shelf','Original','New','Location','best'); end
        text(0.05, 0.04, sprintf('max diff = %g', max(abs(A.(vars{v})(:,1) - A.(vars{v})(:,2)))), ...
            'Units','normalized','FontSize',8);
    end
end
exportgraphics(gcf, [figdir 'stage4_alignment_original.png'], 'Resolution', 200);

%% Figure B: three sill positions
load([rundir 'stage4_examples.mat'], 'RES');
sillcases = {'ex1','ex2','ex3_sill','ex4','ex5','ex6'};
silltitles = extitles([1 2 4 5 6 7]);
Gn = {'G60','G30','G15'}; cols = [0 0 0; 0 0.45 0.74; 0.85 0.33 0.1];
figure('Position',[20 50 1600 700]);
tl = tiledlayout(2, numel(sillcases), 'TileSpacing','compact');
title(tl, 'Effect of sill position under different forcings: profiles at the end of each run');
for v = 1:2
    for ic = 1:numel(sillcases)
        R = RES.(sillcases{ic});
        nexttile((v-1)*numel(sillcases) + ic); hold on; box on
        Sh = AL.(sillcases{ic});
        plot(Sh.([vars{v} 's']), Sh.z, '--', 'Color',[0.6 0.6 0.6], 'LineWidth',1.5);   % shelf
        for g = 1:3
            X = R.(Gn{g});
            plot(X.(vars{v})(:,end), -abs(X.z(:)), 'Color', cols(g,:), 'LineWidth', 1.5);
        end
        yline(-sum(X.H(1:X.ksill,1)), 'k:');       % sill depth (bottom of layer ksill)
        xlabel(xl{v});
        if v == 1, title({silltitles{ic}, sprintf('day %g', X.t(end))}); end
        if ic == 1, ylabel('Depth (m)'); end
        if v == 1 && ic == 1, legend('Shelf','G_{sill} = 60 km','30 km','15 km','Location','best'); end
    end
end
exportgraphics(gcf, [figdir 'stage4_sill_positions.png'], 'Resolution', 200);