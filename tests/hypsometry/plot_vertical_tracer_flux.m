% PLOT_VERTICAL_TRACER_FLUX  Test of vertical heat and salt fluxes for the sill hypsometry.
%
% Loads the example 8 runs (sill at 60, 30 and 15 km from the glacier) and
% looks at the vertical heat and salt fluxes across each layer interface,
% with particular attention to the sill-top interface (ksill/ksill+1).
%
% Two kinds of vertical flux are stored per layer (net into the layer):
%   advective: QTv, QSv  (vertical volume flux carrying upwind T or S)
%   mixing:    QTk, QSk  (diffusive exchange, no volume)
% Cumulative sums from the surface rebuild the flux at each interface.
% Interface k is the boundary between layer k and layer k+1.
% Positive = UPWARD for the advective flux (from get_vertical_fluxes.m).
%
% Checks printed at the end:
%   1. advective interface fluxes match volume flux x upwind T or S
%   2. mixing fluxes are down-gradient (number of interface/time points
%      where they are not; if this is ~all points the sign convention is
%      simply the opposite one, not a bug)
%   3. effective Kz backed out at interfaces ksill-1, ksill, ksill+1 using
%      the interface area width x Lint. If Lint is applied correctly, Kz
%      should be about the same for all three sill positions.
%
% Note: the advective heat flux is relative to 0 degC, so a change of
% sign can mean T crosses 0, not that the flow reverses.

clear; close all

rundir = 'C:/Users/efc4/Documents/MATLAB/fjordrpm_runs/results';
names  = {'example8_Gsill60km', 'example8_Gsill30km', 'example8_Gsill15km'};
labels = {'60 km (mouth)', '30 km', '15 km'};
cols   = [0 0 0; 0 0.45 0.74; 0.85 0.33 0.10];

nr = numel(names);
[errT, errS, nbadT, nbadS, npts] = deal(zeros(nr,1));
Kzeff = nan(nr,3);

f1 = figure('Name','Interface heat and salt fluxes, final-year mean');
t1 = {'advective heat (GW)', 'advective salt (10^3 psu m^3/s)', ...
      'mixing heat (GW)', 'mixing salt (10^3 psu m^3/s)'};
for j = 1:4, ax1(j) = subplot(1,4,j); hold on; end

f2 = figure('Name','Fluxes across the sill-top interface through time');
for j = 1:4, ax2(j) = subplot(4,1,j); hold on; end

for r = 1:nr
    d  = load(fullfile(rundir, [names{r} '.mat']));
    s  = d.s;  p = d.p;
    ks = s.ksill;
    nt = numel(s.t);
    yr = nt-364:nt;                                   % final year of daily output
    rc = p.rhoref*p.cw;                               % J/m^3/K, to convert to W
    T  = s.T;  S = s.S;

    % --- interface fluxes from the stored net-per-layer fluxes
    QVint  = cumsum(s.QVv(1:end-1,:), 1);
    QTint  = cumsum(s.QTv(1:end-1,:), 1);
    QSint  = cumsum(s.QSv(1:end-1,:), 1);
    QTkint = cumsum(s.QTk(1:end-1,:), 1);
    QSkint = cumsum(s.QSk(1:end-1,:), 1);

    % --- check 1: advective flux = volume flux x upwind value
    up    = QVint >= 0;                               % upward: water comes from layer below
    QTchk = (~up).*QVint.*T(1:end-1,:) + up.*QVint.*T(2:end,:);
    QSchk = (~up).*QVint.*S(1:end-1,:) + up.*QVint.*S(2:end,:);
    errT(r) = max(abs(QTint(:) - QTchk(:)));
    errS(r) = max(abs(QSint(:) - QSchk(:)));

    % --- check 2: mixing is down-gradient
    % upward flux (positive) should go with the layer below being warmer/saltier
    dT = T(2:end,:) - T(1:end-1,:);                   % lower minus upper
    dS = S(2:end,:) - S(1:end-1,:);
    tolT = 1e-9*max(abs(QTkint(:)));  tolS = 1e-9*max(abs(QSkint(:)));
    nbadT(r) = nnz(QTkint.*dT < 0 & abs(QTkint) > tolT);
    nbadS(r) = nnz(QSkint.*dS < 0 & abs(QSkint) > tolS);
    npts(r)  = numel(QTkint);

    % --- check 3: effective Kz at the interfaces around the sill (final year)
    Lint = min(s.Llay(1:end-1), s.Llay(2:end));
    Hsum = s.H(1:end-1) + s.H(2:end);
    kk = ks-1:ks+1;
    for j = 1:3
        k = kk(j);
        m = abs(dS(k,yr)) > 1e-6;                     % skip times with no gradient
        if any(m)
            Kz = QSkint(k,yr(m))*Hsum(k) ./ (2*p.W*Lint(k)*dS(k,yr(m)));
            Kzeff(r,j) = median(Kz);
        end
    end

    % --- figure 1: final-year mean profiles
    zint = -cumsum(s.H(1:end-1));
    prof = {rc*mean(QTint(:,yr),2)/1e9, mean(QSint(:,yr),2)/1e3, ...
            rc*mean(QTkint(:,yr),2)/1e9, mean(QSkint(:,yr),2)/1e3};
    for j = 1:4
        plot(ax1(j), prof{j}, zint, '-o', 'color', cols(r,:), 'markersize', 3, ...
            'DisplayName', labels{r});
    end

    % --- figure 2: sill-top interface through time
    ts = {rc*QTint(ks,:)/1e9, QSint(ks,:)/1e3, rc*QTkint(ks,:)/1e9, QSkint(ks,:)/1e3};
    for j = 1:4
        plot(ax2(j), s.t/365, ts{j}, '-', 'color', cols(r,:), 'DisplayName', labels{r});
    end
end

zsill = -sum(s.H(1:ks));
for j = 1:4
    yline(ax1(j), zsill, 'k--', 'sill', 'HandleVisibility', 'off');
    xline(ax1(j), 0, 'k:', 'HandleVisibility', 'off');
    xlabel(ax1(j), t1{j}); grid(ax1(j), 'on'); box(ax1(j), 'on');
    ylabel(ax2(j), t1{j}); grid(ax2(j), 'on'); box(ax2(j), 'on');
end
ylabel(ax1(1), 'depth (m)');
legend(ax1(1), 'location', 'best');
title(ax1(1), 'positive = upward');
legend(ax2(1), 'location', 'best');
title(ax2(1), sprintf('Interface %d/%d (sill top), positive = upward', ks, ks+1));
xlabel(ax2(4), 'time (years)');

% --- print the checks
fprintf('\nChecks 1 and 2 (whole record)\n');
fprintf('%-16s %12s %12s %16s %16s\n', 'run', 'adv T err', 'adv S err', ...
    'up-gradient T', 'up-gradient S');
for r = 1:nr
    fprintf('%-16s %12.3g %12.3g %9d/%-7d %8d/%-7d\n', labels{r}, errT(r), errS(r), ...
        nbadT(r), npts(r), nbadS(r), npts(r));
end
fprintf('\nCheck 3: effective Kz (m^2/s), final-year median\n');
fprintf('%-16s %14s %14s %14s\n', 'run', sprintf('interface %d', ks-1), ...
    sprintf('interface %d', ks), sprintf('interface %d', ks+1));
for r = 1:nr
    fprintf('%-16s %14.3g %14.3g %14.3g\n', labels{r}, Kzeff(r,:));
end
fprintf('(NaN = no salinity gradient at that interface in the final year)\n\n');
