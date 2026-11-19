function b = check_budgets(s, p, label)
% CHECK_BUDGETS Step-by-step salt, heat and volume budgets for a FjordRPM
% run saved at every timestep (p.t_save = t). Prints a summary and returns
% residual time series in structure b.
%   Salt/heat: change in total content (sum V.*S, V.*T) over each step must
%   equal dt x (sum of all fluxes). Stored S,T are after unstable-layer
%   mixing, so the mixing term (QSc, QTc) of the FOLLOWING step is included.
%   Internal fluxes (QSk, QSv) and unstable-layer mixing (QSc) should sum to 0.
%   Volume: the volume fluxes in every layer should sum to zero.

[N, nt] = size(s.S);
V   = s.V(:);
dts = diff(s.t(:))' * p.sid;            % length of each step (s), 1 x (nt-1)
dtn = [dts(2:end), dts(end)];           % length of the following step
P   = @(Q) reshape(sum(Q,1), N, nt);    % sum plume fluxes over plumes
j   = 1:nt-1;                           % fluxes at step i move i -> i+1
rel = @(a, scale) a ./ max(scale, realmin);

% ----- salt -----
QSbnd = P(s.QSp) + s.QSs + s.QSi + s.QSsurf;   % boundary fluxes
QSint = s.QSk + s.QSv;                         % internal fluxes
CS = sum(V.*s.S, 1);                           % total salt content
b.resS = diff(CS) - dts.*sum(QSbnd(:,j) + QSint(:,j), 1) - dtn.*sum(s.QSc(:,j+1), 1);
b.cumS = cumsum(b.resS) / CS(1);

% ----- heat -----
QTbnd = P(s.QTp) + s.QTs + s.QTi + s.QTsurf;
QTint = s.QTk + s.QTv;
CT = sum(V.*s.T, 1);
CTscale = sum(V.*abs(s.T(:,1)));               % T can be near 0, so scale by |T|
b.resT = diff(CT) - dts.*sum(QTbnd(:,j) + QTint(:,j), 1) - dtn.*sum(s.QTc(:,j+1), 1);
b.cumT = cumsum(b.resT) / CTscale;
Tf = p.l1*s.S + p.l2 + p.l3*abs(s.z(:));       % in-situ freezing point
b.nfreeze = nnz(any(abs(s.T - Tf) < 1e-12, 1)); % steps where the freezing reset fired

% ----- volume -----
QVall = P(s.QVp) + s.QVs + s.QVk + s.QVi + s.QVv + s.QVsurf + s.QVc;
QVbnd = P(s.QVp) + s.QVs + s.QVi + s.QVsurf;
b.cumV = cumsum(dts.*sum(QVbnd(:,j),1)) / sum(V);

% ----- summary -----
fprintf('\n%s (%d steps)\n', label, nt-1);
fprintf('  Salt:   max step residual / total salt = %.1e;  cumulative after run = %.1e\n', max(abs(b.resS))/CS(1), b.cumS(end));
fprintf('          internal fluxes: max|sum| / size = %.1e;  unstable mixing: max|sum| / size = %.1e\n', ...
    rel(max(abs(sum(QSint(:,j),1))), max(sum(abs(QSint(:,j)),1))), rel(max(abs(sum(s.QSc,1))), max(sum(abs(s.QSc),1))));
fprintf('  Heat:   max step residual / total |heat| = %.1e;  cumulative after run = %.1e\n', max(abs(b.resT))/CTscale, b.cumT(end));
fprintf('          internal fluxes: max|sum| / size = %.1e;  unstable mixing: max|sum| / size = %.1e\n', ...
    rel(max(abs(sum(QTint(:,j),1))), max(sum(abs(QTint(:,j)),1))), rel(max(abs(sum(s.QTc,1))), max(sum(abs(s.QTc),1))));
fprintf('          steps where freezing reset fired: %d\n', b.nfreeze);
fprintf('  Volume: max |sum of volume fluxes in a layer| / boundary flux size = %.1e\n', ...
    rel(max(abs(QVall(:,j)),[],'all'), max(sum(abs(QVbnd(:,j)),1))));
fprintf('          net boundary volume change after run / fjord volume = %.1e\n', b.cumV(end));
end