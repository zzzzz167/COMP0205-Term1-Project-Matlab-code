% Compare candidate tension springs in a symmetric ideal rhombus clamp.
% Lengths: mm; spring stiffness: N/mm; forces: N; mass: kg.
% Static model: two wall contacts share the weight; no dynamic loads,
% link weight, joint friction or safety factor are included.
% Output: rhombus_force_anlyse.png in the current MATLAB folder.


clc; clear;

L_list = [130 140];
D = linspace(160, 260, 1001);
e = 15;

m = 2;
g = 9.81;
mu_ref = 0.4;

% Candidate spring data: free length l0, stiffness k, initial tension F0,
% and maximum permitted total length smax. Verify against supplier data
% before using the predictions for hardware selection.
springID = {'80852', '80862', '81091', '80864'};
l0 = [101.6 101.6 101.6 127];
k = [0.49 0.75 0.77 0.54];
F0 = [8.9 8.9 8.9 8.9];
smax = [261.62,228.60,248.92,302.26];

ivory = [250 249 246]/255;
red   = [179 20 36]/255;
navy  = [36 50 61]/255;
teal  = [64 111 116]/255;
gold  = [161 116 54]/255;
grey  = [210 207 202]/255;
coral = [205 104 92]/255;
plum  = [116 102 131]/255;

colors = [red; navy; teal; gold; coral; plum];
refColor = [110 107 104]/255;

nL = numel(L_list);
nSpring = numel(springID);

N = nan(nL, nSpring, numel(D));
mu_req = nan(size(N));

% Remove the two pad offsets to obtain the horizontal hinge spacing.
w = D - 2*e;

for i = 1:nL
    L = L_list(i);

    geometryOK = (w > 0) & (w < 2*L);
    s = nan(size(D));
    s(geometryOK) = sqrt(4*L^2 - w(geometryOK).^2);

    for j = 1:nSpring
        % Keep only real geometry and tension springs within their length limits.
        % NaN outside this mask produces gaps rather than misleading curves.
        valid = geometryOK & (s > l0(j)) & (s <= smax(j));

        % Ideal force transfer gives normal force per wall N = Fs*w/s.
        % Two contacts provide total available friction 2*mu*N.
        Fs = F0(j) + k(j)*(s(valid) - l0(j));
        Nvalid = Fs .* w(valid) ./ s(valid);

        N(i,j,valid) = Nvalid;
        mu_req(i,j,valid) = m*g ./ (2*Nvalid);
    end
end

N_hold = m*g/(2*mu_ref);
Nfinite = N(isfinite(N));
mufinite = mu_req(isfinite(mu_req));

N_top = 1.10 * max([Nfinite(:); N_hold]);
mu_top = 1.10 * max([mufinite(:); mu_ref]);


fig = figure('Color', ivory, ...
    'Position', [100 100 1150 760]);

tl = tiledlayout(2,2, ...
    'TileSpacing','compact', ...
    'Padding','compact');

axN = gobjects(1,nL);
axMu = gobjects(1,nL);

for i = 1:nL
    axN(i) = nexttile(tl,i);
    hold on;

    for j = 1:nSpring
        plot(D, squeeze(N(i,j,:)), ...
            'Color', colors(j,:), ...
            'LineWidth', 2, ...
            'DisplayName', springID{j});
    end

    yline(N_hold, '--', ...
        'Color', refColor, ...
        'LineWidth', 1.5, ...
        'DisplayName', sprintf( ...
        'Static reference: %.1f N (assumed mu = %.1f)', ...
        N_hold, mu_ref));

    title(sprintf('Link length L = %d mm', L_list(i)));
    xlabel('Wall gap D (mm)');
    ylabel('Normal force per wall N (N)');
    xlim([D(1), D(end)]);
    ylim([0,N_top]);
    grid on; box on;

    axMu(i) = nexttile(tl,nL+i);
    hold on;

    for j = 1:nSpring
        plot(D, squeeze(mu_req(i,j,:)), ...
            'Color', colors(j,:), ...
            'LineWidth', 2, ...
            'DisplayName', springID{j});
    end

    yline(mu_ref, '--', ...
        'Color', refColor, ...
        'LineWidth', 1.5, ...
        'DisplayName', 'Assumed reference: mu = 0.4');

    xlabel('Wall gap D (mm)');
    ylabel('Required static friction coefficient \mu_{req}');
    xlim([D(1), D(end)]);
    ylim([0,mu_top]);
    grid on; box on;
end

linkaxes(axN,'xy');
linkaxes(axMu,'xy');

allAxes = [axN, axMu];

set(allAxes, ...
    'Color', ivory, ...
    'XColor', navy, ...
    'YColor', navy, ...
    'GridColor', grey, ...
    'GridAlpha', 0.6, ...
    'FontSize', 11, ...
    'LineWidth', 1);

for ax = allAxes
    set(get(ax,'Title'), 'Color', navy);
    set(get(ax,'XLabel'), 'Color', navy);
    set(get(ax,'YLabel'), 'Color', navy);
end

lgdN = legend(axN(1), ...
    'Location','best','FontSize',9);

lgdMu = legend(axMu(1), ...
    'Location','best','FontSize',9);

set([lgdN,lgdMu], ...
    'Color', ivory, ...
    'TextColor', navy, ...
    'EdgeColor', grey);

title(tl, {
    'm = 2 kg, e = 15 mm; gaps in curves indicate invalid spring lengths'}, ...
    'FontWeight', 'bold', ...
    'FontSize', 14, ...
    'Color', navy);

exportgraphics(fig, 'rhombus_force_anlyse.png', 'Resolution', 300);
