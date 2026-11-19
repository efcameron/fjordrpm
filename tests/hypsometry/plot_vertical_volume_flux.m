% PLOT_VERTICAL_VOLUME_FLUX  Test of vertical volume fluxes for the sill hypsometry.
%
% Loads the example 8 runs (sill at 60, 30 and 15 km from the glacier),
% rebuilds the vertical volume flux at each layer interface and checks:
%   1. the rebuilt interface flux matches the formula in get_vertical_fluxes.m
%   2. the total volume imbalance is zero (implies zero flux through the bed)
%   3. mixing (QVk) and convection (QVc) carry no volume
%   4. there is no shelf volume flux below the sill
%   5. the flux across the sill-top interface equals the plume entrainment
%      from the layers below the sill
% and plots the sill-interface flux through time and the interface flux
% profiles in the final year.
%
% Sign convention (from get_vertical_fluxes.m): positive = UPWARD.
% Interface k is the boundary between layer k and layer k+1 (bottom of layer k).
% Units: m^3/s.

clear; close all

rundir = 'C:/Users/efc4/Documents/MATLAB/fjordrpm_runs/results';
names  = {'example8_Gsill60km', 'example8_Gsill30km', 'example8_Gsill15km'};
labels = {'60 km (mouth)', '30 km', '15 km'};
cols   = [0 0 0; 0 0.45 0.74; 0.85 0.33 0.10];

nr = numel(names);
[err_rebuild, err_bed, max_QVk, max_QVc, max_QVs_deep, err_sill] = deal(zeros(nr,1));

f1 = figure('Name','Sill-interface volume flux'); hold on
f2 = figure('Name','Interface flux profiles, final year');
ax2a = subplot(1,2,1); hold on
ax2b = subplot(1,2,2); hold on

for r = 1:nr
    d  = load(fullfile(rundir, [names{r} '.mat']));
    s  = d.s;
    ks = s.ksill;
    nt = numel(s.t);

    % --- interface fluxes rebuilt from the stored net-per-layer fluxes
    % QVv(k) = QVint(k) - QVint(k-1), with zero at the surface, so a
    % cumulative sum from the top gives the flux at each interface
    QVint = cumsum(s.QVv(1:end-1,:), 1);             % [N-1 x nt]

    % --- independent rebuild using the formula in get_vertical_fluxes.m
    Qp   = squeeze(sum(s.QVp, 1));                   % plume, summed over plumes [N x nt]
    Qnet = Qp + s.QVs + s.QVi + s.QVsurf;            % [N x nt]
    QVint_check = -cumsum(Qnet(1:end-1,:), 1);

    % --- checks
    err_rebuild(r)  = max(abs(QVint(:) - QVint_check(:)));
    err_bed(r)      = max(abs(sum(Qnet, 1)));         % total imbalance = flux through bed
    max_QVk(r)      = max(abs(s.QVk(:)));
    max_QVc(r)      = max(abs(s.QVc(:)));
    max_QVs_deep(r) = max(max(abs(s.QVs(ks+1:end,:))));

    Qsill       = QVint(ks,:);                        % flux across the sill-top interface
    Qplume_deep = sum(Qp(ks+1:end,:), 1);             % plume volume flux from layers below the sill
    err_sill(r) = max(abs(Qsill - Qplume_deep));

    % --- figure 1: sill-interface flux through time
    figure(f1)
    plot(s.t/365, Qsill, '-', 'color', cols(r,:), 'linewidth', 1, ...
        'DisplayName', [labels{r} ': interface ' num2str(ks) '/' num2str(ks+1)]);
    plot(s.t/365, Qplume_deep, ':', 'color', cols(r,:), 'linewidth', 1.5, ...
        'DisplayName', [labels{r} ': plume below sill']);

    % --- figure 2: interface profiles in the final year
    zint = -cumsum(s.H(1:end-1));                     % interface depths (m, negative down)
    yr   = nt-364:nt;                                 % final year of daily output
    [~, ipk] = max(s.Qsg(yr));                        % day of peak discharge
    ipk = yr(ipk);

    plot(ax2a, mean(QVint(:,yr), 2), zint, '-o', 'color', cols(r,:), ...
        'markersize', 3, 'DisplayName', labels{r});
    plot(ax2b, QVint(:,ipk), zint, '-o', 'color', cols(r,:), ...
        'markersize', 3, 'DisplayName', labels{r});
end

zsill = -sum(s.H(1:ks));

figure(f1)
xlabel('time (years)'); ylabel('vertical volume flux (m^3/s), positive up');
title('Flux across the sill-top interface vs plume volume flux below the sill');
legend('location', 'best'); grid on; box on

for ax = [ax2a ax2b]
    yline(ax, zsill, 'k--', 'sill', 'HandleVisibility', 'off');
    xline(ax, 0, 'k:', 'HandleVisibility', 'off');
    xlabel(ax, 'interface volume flux (m^3/s), positive up');
    ylabel(ax, 'depth (m)'); grid(ax, 'on'); box(ax, 'on');
    legend(ax, 'location', 'best');
end
title(ax2a, 'Final-year mean');
title(ax2b, 'Final year, day of peak discharge');

% --- print the checks
fprintf('\n%-16s %12s %12s %12s %12s %12s %12s\n', 'run', 'rebuild', 'bed', ...
    'max|QVk|', 'max|QVc|', 'shelf<sill', 'sill-plume');
for r = 1:nr
    fprintf('%-16s %12.3g %12.3g %12.3g %12.3g %12.3g %12.3g\n', labels{r}, ...
        err_rebuild(r), err_bed(r), max_QVk(r), max_QVc(r), max_QVs_deep(r), err_sill(r));
end
fprintf('(all in m^3/s; all should be zero or tiny compared with the fluxes in the figures)\n\n');
