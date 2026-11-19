% test_example_alls.m - original FjordRPM examples 1-6 with the sill
% (a) original code vs new code with the sill at the mouth (exact match expected)
% (b) new code at Gsill = 60, 30, 15 km, saved every step, with budget checks
clear; close all;
orig   = 'C:/Users/efc4/Documents/MATLAB/fjordrpm_orig';
new    = 'C:/Users/efc4/Documents/MATLAB/fjordrpm';
rundir = 'C:/Users/efc4/Documents/MATLAB/fjordrpm_runs/results/';
warning('off','MATLAB:rmpath:DirNotFound');

exnames  = {'ex1','ex2','ex3','ex3_sill','ex4','ex5','ex6'};
exsetup  = {'setup_ex1','setup_ex2','setup_ex3','setup_ex3','setup_ex4','setup_ex5','setup_ex6'};
exsillon = [0 0 0 1 0 0 0];      % 1 = switch the sill on (example 3 has none)
Glist    = [60e3, 30e3, 15e3];
RES = struct();

for ie = 1:numel(exnames)
    nm = exnames{ie};
    fprintf('\n================ %s ================\n', nm);

    % --- (a) original code ---
    rmpath(genpath(new)); rmpath(genpath(orig)); addpath(genpath(orig)); clear functions
    fprintf('original code: %s\n', which('run_model'));
    clearvars -except orig new rundir exnames exsetup exsillon Glist RES ie nm
    eval(exsetup{ie}); if exsillon(ie), p.sill = 1; end
    Ro = run_model(p, t, f, a);

    % --- (a) new code: Gsill not set, then Gsill = L ---
    rmpath(genpath(orig)); addpath(genpath(new)); clear functions
    fprintf('new code:      %s\n', which('run_model'));
    clearvars -except orig new rundir exnames exsetup exsillon Glist RES ie nm Ro
    eval(exsetup{ie}); if exsillon(ie), p.sill = 1; end
    Rn = run_model(p, t, f, a);
    p.Gsill = p.L;
    Rg = run_model(p, t, f, a);

    fn = fieldnames(Ro); nd = [0 0];
    for k = 1:numel(fn)
        nd(1) = nd(1) + ~isequaln(Ro.(fn{k}), Rn.(fn{k}));
        nd(2) = nd(2) + ~isequaln(Ro.(fn{k}), Rg.(fn{k}));
    end
    fprintf('REGRESSION: Gsill not set -> %d of %d fields differ;  Gsill = L -> %d of %d fields differ\n', ...
        nd(1), numel(fn), nd(2), numel(fn));
    RES.(nm).ndiff = nd;

    % --- (b) sill positions, saved every step, budgets checked ---
    if p.sill == 1
        tsave_daily = p.t_save;
        p.t_save = t;
        for ig = 1:numel(Glist)
            p.Gsill = Glist(ig);
            s = run_model(p, t, f, a);
            b = check_budgets(s, p, sprintf('%s, G_sill = %g km', nm, p.Gsill/1e3));
            gname = sprintf('G%d', Glist(ig)/1e3);
            RES.(nm).(gname) = keep(s, ismember(s.t, tsave_daily));   % daily S, T for plotting
            RES.(nm).([gname '_budget']) = b;
        end
    else
        fprintf('No sill in this example: sill-position runs skipped.\n');
    end
end

% restore the normal path (new code only)
rmpath(genpath(orig)); addpath(genpath(new)); clear functions
save([rundir 'stage4_examples.mat'], 'RES');

function k = keep(s, idx)
% keep only what is needed for plotting, at the daily save times
k.t = s.t(idx); k.S = s.S(:,idx); k.T = s.T(:,idx);
k.z = s.z; k.H = s.H; k.V = s.V; k.ksill = s.ksill; k.Llay = s.Llay;
end