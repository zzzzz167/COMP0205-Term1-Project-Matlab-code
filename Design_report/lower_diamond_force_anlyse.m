% Lower diamond clamp: static friction requirement and peak force per rack.
% Lengths in mm, forces in N. Symmetric, rigid, quasi-static model.

clc; clear;

L = 130;                     % Diamond link pivot spacing
e = 15;                      % Pad offset per side
mass = 2;                    % Complete machine mass (kg)
g = 9.81;
holdingRatio = 1.2;
muAssumed = 0.60;
wallGap = linspace(160, 260, 1001);      % One column per wall gap
q = linspace(0, 12, 241).';               % One row per inward displacement

% Rows correspond to the three springs in legend order.
springID = {'80852', '81091', 'LEM120EB 05 M'};
freeLength = [101.6, 101.6, 90.20];
springRate = [0.49, 0.77, 0.210];       % N/mm
initialTension = [8.9, 8.9, 6.56];
maxLength = [261.62, 248.92, 258.19];   % Maximum total length

span = wallGap - 2*e - 2*q;
validGeometry = span > 0 & span < 2*L;
springLength = nan(size(span));
springLength(validGeometry) = sqrt((2*L)^2 - span(validGeometry).^2);

fig = figure('Color', 'w', 'Position', [100 100 1100 455]);
layout = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
axMu = nexttile(layout);
axForce = nexttile(layout);
hold(axMu, 'on');
hold(axForce, 'on');
colors = [179 20 36; 64 111 116; 36 50 61]/255;
styles = {'--', '-.', '-'};
springLines = gobjects(1, numel(springID));

for j = 1:numel(springID)
    valid = validGeometry & springLength > freeLength(j) & springLength <= maxLength(j);
    tension = initialTension(j) + springRate(j)*(springLength - freeLength(j));
    horizontalForce = tension .* span ./ springLength;
    horizontalForce(~valid) = NaN;

    % At q=0 the wall takes this load on each side (racks unloaded).
    normalPerWall = horizontalForce(1,:);
    muRequired = holdingRatio*mass*g ./ (2*normalPerWall);

    % During retraction each rack takes this load. Only plot gaps at which
    % the entire prescribed stroke stays within the spring's working range.
    peakRackForce = max(horizontalForce, [], 1);
    peakRackForce(~all(valid, 1)) = NaN;

    springLines(j) = plot(axMu, wallGap, muRequired, styles{j}, ...
        'Color', colors(j,:), 'LineWidth', 2, 'DisplayName', springID{j});
    plot(axForce, wallGap, peakRackForce, styles{j}, ...
        'Color', colors(j,:), 'LineWidth', 2);
    fprintf('%s: max required mu = %.4f, peak force per rack = %.2f N\n', ...
        springID{j}, max(muRequired, [], 'omitnan'), max(peakRackForce, [], 'omitnan'));
end

yline(axMu, muAssumed, ':', 'Assumed \mu_s = 0.60', ...
    'Color', [0.32 0.32 0.32], 'LineWidth', 1.4, ...
    'LabelHorizontalAlignment', 'center', 'LabelVerticalAlignment', 'top');
title(axMu, '(a) Static holding ratio of 1.2');
ylabel(axMu, 'Required static friction coefficient, \mu_{req}');
title(axForce, '(b) Retraction over 0–12 mm per pad');
ylabel(axForce, 'Peak retraction force per rack (N)');

for ax = [axMu, axForce]
    xlabel(ax, 'Wall gap (mm)');
    xlim(ax, [wallGap(1), wallGap(end)]);
    grid(ax, 'on');
    box(ax, 'on');
    set(ax, 'Color', 'w', 'FontSize', 12, 'GridAlpha', 0.15);
end
ylim(axMu, [0, 0.7]);
ylim(axForce, [0, 80]);
lgd = legend(axMu, springLines, springID, 'Orientation', 'horizontal', 'Box', 'off');
lgd.Layout.Tile = 'south';

exportgraphics(fig, 'lower_diamond_force_anlyse.png', 'Resolution', 300);
