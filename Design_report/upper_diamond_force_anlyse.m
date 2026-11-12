clear; clc;

ivory = [250 249 246]/255;
red   = [179 20 36]/255;
navy  = [36 50 61]/255;
teal  = [64 111 116]/255;
gold  = [161 116 54]/255;
grey  = [210 207 202]/255;
coral = [205 104 92]/255;
plum  = [116 102 131]/255;

%% Geometry and loads (mm, N, kg)
D  = 160:0.1:260;       % Wall gap
L  = 130;               % Diamond link length
e  = 15;                % Pad offset per side
La = 178;               % Crossed-link length
a  = 60;                % Half the 120 mm crossbeam pivot spacing

g  = 9.81;
M  = 2.0;               % Total machine mass
mu = 0.60;              % Assumed static friction coefficient
holdingRatio = 1.20;

P  = 1.5*g;             % Downward load through the crossbeam
Wu = 0.5*g;             % Weight of the upper module

%% Upper spring: Lee Spring LE 037E 10 M
l0 = 88.90;             % Free length (mm)
k  = 0.070;             % Spring rate (N/mm)
F0 = 1.78;              % Initial tension (N)

%% Upper clamp model (Section 3.3)
w = D - 2*e;                    % Distance BD
l = sqrt(4*L^2 - w.^2);         % Spring length AC
x = l/2 + a;                    % Horizontal projection of a crossed link
h = sqrt(La^2 - x.^2);          % Vertical projection

Fs = F0 + k*(l - l0);
N0 = Fs .* w ./ l;              % Spring contribution per wall
C  = (x ./ (2*h)) .* (w ./ l);  % Normal force gain per unit crossbeam load

% (a) Downward loading: normal reaction per wall and required friction
Nu = N0 + C*P;
muReq = holdingRatio*M*g ./ (2*Nu);

% (b) Upward loading: N_push = N0 - C*U.
% At the onset of sliding, U = Wu + 2*mu*N_push.
Ustart = (Wu + 2*mu*N0) ./ (1 + 2*mu*C);

[muPeak, iMu] = max(muReq);
[forcePeak, iForce] = max(Ustart);

fig = figure('Position', [100 100 1050 410]);

% Use MATLAB's light theme when available (R2025a or later).
if isprop(fig, 'Theme')
    theme(fig, 'light');
else
    set(fig, 'Color', 'white');
end

tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

%% (a) Static holding
ax1 = nexttile;
plot(D, muReq, 'Color', teal, 'LineWidth', 2);
hold on;
yline(mu, '--', sprintf('Assumed \\mu_s = %.2f', mu), ...
    'LabelHorizontalAlignment', 'left', ...
    'LabelVerticalAlignment', 'top');

[muMax, iMax] = max(muReq);
[muMin, iMin] = min(muReq);

plot(D([iMax iMin]), [muMax muMin], 'o', ...
    'Color', teal, 'MarkerFaceColor', teal, 'MarkerSize', 5);

text(D(iMax), muMax - 0.008, ...
    sprintf('Max %.3f at %.1f mm', muMax, D(iMax)), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');

text(D(iMin) + 2, muMin - 0.008, ...
    sprintf('Min %.3f at %.1f mm', muMin, D(iMin)), ...
    'VerticalAlignment', 'top');

xlabel('Wall gap (mm)');
ylabel('Required static friction coefficient');
title('(a) Static holding');
xlim([160 260]);
ylim([0.45 0.70]);
yticks(0.45:0.05:0.70);
grid on;
box on;

%% (b) Onset of upward sliding
ax2 = nexttile;
plot(D, Ustart, 'Color', navy, 'LineWidth', 2);
hold on;

[forceMax, iMax] = max(Ustart);
[forceMin, iMin] = min(Ustart);

plot(D([iMax iMin]), [forceMax forceMin], 'o', ...
    'Color', navy, 'MarkerFaceColor', navy, 'MarkerSize', 5);

text(D(iMax), forceMax + 0.08, ...
    sprintf('Max %.2f N at %.1f mm', forceMax, D(iMax)), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');

text(D(iMin) + 2, forceMin - 0.08, ...
    sprintf('Min %.2f N at %.1f mm', forceMin, D(iMin)), ...
    'VerticalAlignment', 'top');

xlabel('Wall gap (mm)');
ylabel('Upward starting force (N)');
title('(b) Onset of upward sliding');
xlim([160 260]);
ylim([floor(forceMin) - 0.1, ceil(forceMax) + 0.2]);
grid on;
box on;

exportgraphics(fig, 'upper_diamond_force_anlyse.png', 'Resolution', 300);