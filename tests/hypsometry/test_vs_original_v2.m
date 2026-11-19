% test_vs_original.m - compare the new code (sill at the mouth) with the
% original FjordRPM under the example 8 synthetic (depth-varying) shelf
clear; close all;
orig   = 'C:/Users/efc4/Documents/MATLAB/fjordrpm_orig';
new    = 'C:/Users/efc4/Documents/MATLAB/fjordrpm';
rundir = 'C:/Users/efc4/Documents/MATLAB/fjordrpm_runs/results/';
warning('off','MATLAB:rmpath:DirNotFound');
cases = {'original','new_default','new_Gsill60'};

for c = 1:numel(cases)
    % put exactly one version of the code on the path
    rmpath(genpath(new)); rmpath(genpath(orig));
    if c == 1, addpath(genpath(orig)); else, addpath(genpath(new)); end
    clear functions
    w = which('run_model','-all');
    fprintf('\n%s: run_model found in %d place(s): %s\n', cases{c}, numel(w), strjoin(w', '; '));
    setup_example8                         % defines p, t, f, a (no addpath inside)
    if c == 3, p.Gsill = p.L; end          % explicit sill at the mouth
    R.(cases{c}) = run_model(p, t, f, a);
end

% restore the normal path (new code only)
rmpath(genpath(orig)); addpath(genpath(new)); clear functions

% confirm the forcing really was depth-varying
fprintf('\nInitial fjord S: %.2f to %.2f;  shelf S in layers: %.2f to %.2f\n', ...
    min(R.original.S(:,1)), max(R.original.S(:,1)), min(R.original.Ss(:,1)), max(R.original.Ss(:,1)));
fprintf('Initial fjord T: %.2f to %.2f degC\n', min(R.original.T(:,1)), max(R.original.T(:,1)));

% field-by-field comparison with the original output
fn = fieldnames(R.original);
for c = 2:3
    X = R.(cases{c}); nd = 0;
    for k = 1:numel(fn)
        if ~isequaln(R.original.(fn{k}), X.(fn{k}))
            nd = nd + 1;
            fprintf('  %s: field %s differs\n', cases{c}, fn{k});
        end
    end
    fprintf('%s: %d of %d fields differ from the original. Fields only in new output: %s\n', ...
        cases{c}, nd, numel(fn), strjoin(setdiff(fieldnames(X), fn)', ', '));
end
save([rundir 'compare_original_v2_synthetic_shelf.mat'], 'R');

% figure: profiles from both codes, and differences through time
z = -abs(R.original.z); ty = R.original.t/365;
figure('Position',[50 50 1400 450]);
tl = tiledlayout(1,4,'TileSpacing','compact');
title(tl,'New code vs original FjordRPM: example 8 synthetic shelf, sill at the mouth');
vars = {'S','T'}; units = {'','(^oC)'};
for v = 1:2
    nexttile; hold on; box on
    plot(R.original.([vars{v} 's'])(:,1), z, 'k-', 'LineWidth', 1.5);
    plot(R.original.(vars{v})(:,end), z, 'b-', 'LineWidth', 2.5);
    plot(R.new_Gsill60.(vars{v})(:,end), z, 'r--', 'LineWidth', 1.5);
    xlabel([vars{v} ' ' units{v}]); ylabel('Depth (m)');
    if v == 1, legend('Shelf','Original, year 15','New, year 15','Location','best'); end
end
for v = 1:2
    nexttile; hold on; box on
    plot(ty, max(abs(R.new_default.(vars{v}) - R.original.(vars{v})),[],1), 'LineWidth', 2);
    plot(ty, max(abs(R.new_Gsill60.(vars{v}) - R.original.(vars{v})),[],1), '--', 'LineWidth', 1.5);
    xlabel('Years'); ylabel(sprintf('max over layers |%s_{new} - %s_{orig}|', vars{v}, vars{v}));
    if v == 1, legend('New, G_{sill} not set','New, G_{sill} = L','Location','best'); end
end
exportgraphics(gcf, 'C:/Users/efc4/Documents/MATLAB/fjordrpm_runs/figures/compare_original_v2_synthetic_shelf.png', 'Resolution', 200);