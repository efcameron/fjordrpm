% get basic constants and default controlling parameters
p = default_parameters;

% can adjust any of the default parameters afterwards if needed
% p.C0 = 5e4; % for example adjust shelf exchange parameter
% p.run_plume_every = 10; % or update plume model only every 10 time steps

% set up fjord geometry
p.W = 6e3; % fjord width (m)
p.L = 60e3; % fjord length (m)
p.H = 800; % fjord depth (m)
p.sill = 1; % p.sill=1 for presence of sill, p.sill=0 for no sill
p.Hsill = 400; % sill depth below surface (m), only used if p.sill=1

% set up glacier geometry
% (only used if there is non-zero subglacial discharge)
p.Hgl = 800; % grounding line depth (m)
p.Wp = 250; % subglacial discharge plume width (m)

% in the case of multiple plumes, either at the same glacier or at
% different glaciers, specify vectors of grounding line depth and plume
% width. for example, 3 glaciers of grounding line depth 800, 700, 600 m
% and plume width 300, 200 and 300 m would require
% p.Hgl = [800,700,600];
% p.Wp = [300,200,300];

% set up model layers
p.N = 40; % number of layers
a.H0 = (p.H/p.N)*ones(p.N,1); % layer thicknesses, here taken to be equal

% set up time stepping
dt = 0.2; % time step (in days)
t_end = 15*365; % time to end the simulation (in days)
t = 0:dt:t_end; % resulting time vector for simulation
p.t_save = 0:1:t_end; % times on which to save output


% set up shelf forcing - synthetic Greenland-style profile, constant in time
% temperature: cold polar-type water over warm Atlantic-type water (smooth step)
% salinity: increases exponentially with depth, freshest at the surface
% for more complexity see other examples
% f.ts must have dimensions 1 x nt
% f.zs must have dimensions nz x 1
% f.Ss and f.Ts must have dimensions nz x nt

f.ts = [0,t_end]; % time vector for shelf forcing
f.zs = (-p.H:0)'; % depth vector for shelf forcing (negative below surface)
Stop = 30; Sbottom = 35; % salinity at the surface and the deep value
Tpw = -1.0; Taw = 3.5; % temperature of upper and deep water (degC)
zc = 400; w = 75; % depth and width of the temperature transition (m)
zi = 250; % e-folding depth of the salinity profile (m)
frac = 0.5*(1 + tanh((-f.zs - zc)/w)); % 0 near the surface, 1 at depth
f.Ss = (Sbottom-(Sbottom-Stop)*exp(f.zs/zi))*ones(1,length(f.ts)); % shelf salinity on (zs,ts)
f.Ts = (Tpw + (Taw-Tpw)*frac)*ones(1,length(f.ts)); % shelf temperature on (zs,ts)


% set up subglacial discharge forcing
% here use idealised seasonal gaussian peaked at julian day 200
% f.tsg must have dimensions 1 x nt
% f.Qsg must have dimensions num plumes x nt
f.tsg = t; % time vector for subglacial discharge
f.Qsg = 300*exp(-((mod(f.tsg,365)-200)/30).^2); % subglacial discharge on tsg

% in the case of multiple plumes we add more rows to f.Qsg
% for example for three plumes with the same subglacial discharge
% f.Qsg(1,:) = 300*exp(-((mod(t,365)-200)/30).^2);
% f.Qsg(2,:) = 300*exp(-((mod(t,365)-200)/30).^2);
% f.Qsg(3,:) = 300*exp(-((mod(t,365)-200)/30).^2);

% fjord initial conditions
% set up to be same as initial shelf profiles
[a.T0, a.S0] = bin_shelf_profiles(f.Ts(:,1), f.Ss(:,1), f.zs, a.H0);

% set up icebergs - in this example there are no icebergs
a.I0 = 0*a.H0;
