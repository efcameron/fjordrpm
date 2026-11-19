% plot_dt_test.m - analysis and figures for the timestep test
% Compares the Gsill = 15 km run (example 8 forcing) at dt = 0.2, 0.1, 0.05 days.
% Needs, in fjordrpm_runs/results:
%   example8_Gsill15km.mat, example8_Gsill30km.mat  (dt = 0.2, from examples/example8_synthetic_shelf.m)
%   example8_Gsill15km_dt0p1.mat, example8_Gsill15km_dt0p05.mat  (from test_dt_15km.m)
clear; close all;
resdir = 'C:/Users/efc4/Documents/MATLAB/fjordrpm_runs/results/';
figdir = 'C:/Users/efc4/Documents/MATLAB/fjordrpm_runs/figures/';

A   = load([resdir 'example8_Gsill15km.mat']);        % dt = 0.2
B   = load([resdir 'example8_Gsill15km_dt0p1.mat']);  % dt = 0.1
C   = load([resdir 'example8_Gsill15km_dt0p05.mat']); % dt = 0.05
G30 = load([resdir 'example8_Gsill30km.mat']);        % 30 km, dt = 0.2, for scale
layers = [20 21 30 40];
ty = A.s.t/365;
yr  = @(tt) floor(tt/365) + 1;  doy = @(tt) mod(tt, 365);

%% 1. all runs saved on the same days?
fprintf('Max save-time mismatch: 0.2 vs 0.1 = %g days, 0.2 vs 0.05 = %g days\n', ...
    max(abs(A.s.t - B.s.t)), max(abs(A.s.t - C.s.t)));

%% 2. largest differences over all layers and days, whole run and after year 1
idx = A.s.t > 365;
for v = {'S','T'}
    X = A.s.(v{1}); Y = B.s.(v{1}); Z = C.s.(v{1});
    D1 = abs(X - Y); D2 = abs(Y - Z);
    [m1,i1] = max(D1,[],'all','linear'); [k1,j1] = ind2sub(size(D1),i1);
    [m2,i2] = max(D2,[],'all','linear'); [k2,j2] = ind2sub(size(D2),i2);
    fprintf('\n%s, whole run: max|0.2-0.1| = %.2e (layer %d, yr %d, doy %d); max|0.1-0.05| = %.2e (layer %d, yr %d, doy %d); ratio %.2f\n', ...
        v{1}, m1, k1, yr(A.s.t(j1)), doy(A.s.t(j1)), m2, k2, yr(A.s.t(j2)), doy(A.s.t(j2)), m1/m2);
    E1 = D1(:,idx); E2 = D2(:,idx); tt = A.s.t(idx);
    [n1,i1] = max(E1,[],'all','linear'); [k1,j1] = ind2sub(size(E1),i1);
    n2 = max(E2,[],'all');
    fprintf('%s, years 2-15: max|0.2-0.1| = %.2e (layer %d, yr %d, doy %d); max|0.1-0.05| = %.2e; ratio %.2f\n', ...
        v{1}, n1, k1, yr(tt(j1)), doy(tt(j1)), n2, n1/n2);
end

%% 3. timestep differences compared with the sill signal (15 vs 30 km)
fprintf('\nLayer  var  total change  max|15-30 km|  max|dt0.2-dt0.1|  dt diff / geometry diff\n');
for k = layers
    for v = {'S','T'}
        X = A.s.(v{1}); Y = B.s.(v{1}); Z = G30.s.(v{1});
        chg = abs(X(k,end) - X(k,1)); geo = max(abs(X(k,:) - Z(k,:))); dtd = max(abs(X(k,:) - Y(k,:)));
        fprintf('%4d   %s    %9.3f    %11.3f    %14.2e    %10.1e\n', k, v{1}, chg, geo, dtd, dtd/geo);
    end
end

%% 4. convergence: max and RMS ratios per layer
fprintf('\nLayer var   max 0.2-0.1  max 0.1-0.05  ratio    rms 0.2-0.1  rms 0.1-0.05  ratio   day of max (yr, doy)\n');
for k = layers
    for v = {'S','T'}
        X = A.s.(v{1})(k,:); Y = B.s.(v{1})(k,:); Z = C.s.(v{1})(k,:);
        m1 = max(abs(X-Y)); m2 = max(abs(Y-Z));
        r1 = sqrt(mean((X-Y).^2)); r2 = sqrt(mean((Y-Z).^2));
        [~,i] = max(abs(X-Y));
        fprintf('%4d   %s    %.2e     %.2e    %5.2f    %.2e     %.2e    %5.2f    %2d, %3d\n', ...
            k, v{1}, m1, m2, m1/m2, r1, r2, r1/r2, yr(A.s.t(i)), doy(A.s.t(i)));
    end
end

%% Figures 1-2: timeseries and differences from the dt = 0.05 run
for v = {'S','T'}
    figure('Position',[50 50 1400 600]);
    tl = tiledlayout(2, numel(layers), 'TileSpacing','compact');
    title(tl, sprintf('Timestep test, G_{sill} = 15 km: %s', v{1}));
    for j = 1:numel(layers)
        k = layers(j);
        nexttile(j); hold on; box on
        plot(ty, A.s.(v{1})(k,:), 'LineWidth',1.5);
        plot(ty, B.s.(v{1})(k,:), '--', 'LineWidth',1.5);
        plot(ty, C.s.(v{1})(k,:), ':', 'LineWidth',1.5);
        title(sprintf('Layer %d', k)); xlabel('Years');
        if j == 1, ylabel(v{1}); legend('dt = 0.2','dt = 0.1','dt = 0.05','Location','best'); end
        nexttile(j + numel(layers)); hold on; box on
        plot(ty, A.s.(v{1})(k,:) - C.s.(v{1})(k,:), 'LineWidth',1.2);
        plot(ty, B.s.(v{1})(k,:) - C.s.(v{1})(k,:), 'LineWidth',1.2);
        xlabel('Years');
        if j == 1, ylabel(sprintf('%s minus dt = 0.05 run', v{1})); legend('dt = 0.2','dt = 0.1','Location','best'); end
    end
    exportgraphics(gcf, [figdir 'dt_test_15km_' v{1} '.png'], 'Resolution', 200);
end

%% Figure 3: max and RMS differences in every layer
figure('Position',[50 50 1100 500]);
tl = tiledlayout(1,4,'TileSpacing','compact');
title(tl,'Timestep test, G_{sill} = 15 km: differences by layer');
for v = {'S','T'}
    X = A.s.(v{1}); Y = B.s.(v{1}); Z = C.s.(v{1});
    for stat = {'max','rms'}
        if strcmp(stat{1},'max'), f1 = max(abs(X-Y),[],2); f2 = max(abs(Y-Z),[],2);
        else,                     f1 = sqrt(mean((X-Y).^2,2)); f2 = sqrt(mean((Y-Z).^2,2)); end
        nexttile; hold on; box on
        plot(f1, 1:40, 'o-'); plot(f2, 1:40, 's-');
        yline(A.s.ksill + 0.5, 'k--', 'sill');
        set(gca,'YDir','reverse','XScale','log');
        xlabel(sprintf('%s %s difference', stat{1}, v{1})); ylabel('Layer');
        legend('0.2 vs 0.1','0.1 vs 0.05','Location','best');
    end
end
exportgraphics(gcf, [figdir 'dt_test_15km_bylayer.png'], 'Resolution', 200);

%% Figure 4: layer 40 through year 5 (the late-autumn threshold event)
y5 = 5; win = A.s.t >= (y5-1)*365 & A.s.t < y5*365;
d = A.s.t(win) - (y5-1)*365;
figure('Position',[50 50 1100 750]);
tiledlayout(3,1,'TileSpacing','compact');
nexttile; hold on; box on
plot(d, A.s.S(40,win),'LineWidth',1.5); plot(d, B.s.S(40,win),'--','LineWidth',1.5); plot(d, C.s.S(40,win),':','LineWidth',1.5);
ylabel('S, layer 40'); legend('dt = 0.2','dt = 0.1','dt = 0.05','Location','best');
title(sprintf('Layer 40 salinity through year %d', y5));
nexttile; hold on; box on
plot(d, A.s.S(40,win)-C.s.S(40,win),'LineWidth',1.2); plot(d, B.s.S(40,win)-C.s.S(40,win),'LineWidth',1.2);
ylabel('minus dt = 0.05 run'); legend('dt = 0.2','dt = 0.1','Location','best');
nexttile; plot(d, 300*exp(-((d-200)/30).^2),'k','LineWidth',1.2);
ylabel('Q_{sg} (m^3 s^{-1})'); xlabel('Day of year');
exportgraphics(gcf, [figdir 'dt_test_15km_layer40_year5.png'], 'Resolution', 200);