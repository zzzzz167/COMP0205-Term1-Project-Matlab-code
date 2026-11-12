% Compare ideal scissor height for one, two and three identical stages.
% Ls and b are in mm; H = n*sqrt(Ls^2-b^2). Rigid links and ideal pins
% are assumed. The shaded b interval is the selected actuator travel.
% Output: Nscissor_fork_anlyse.png in the current MATLAB folder.


clc; clear;

n = [1 2 3];
Ls = 150;
b = 0:0.1:Ls;
b_min = 40; b_max = 90;

h = sqrt(Ls^2 - b.^2);

ivory = [250 249 246]/255;
red   = [179 20 36]/255;
navy  = [36 50 61]/255;
teal  = [64 111 116]/255;
gold  = [161 116 54]/255;
grey  = [210 207 202]/255;
coral = [205 104 92]/255;
plum  = [116 102 131]/255;

colors = [navy; red; teal; gold; coral; plum];

fig = figure('Color', ivory);
ax = axes(fig);
hold(ax, 'on');

for i = 1:numel(n)
    H = n(i)*h;

    % Height gained as the horizontal spacing decreases from b_max to b_min.
    extension = interp1(b, H, b_min) - interp1(b, H, b_max);

    plot(ax, b, H, 'LineWidth', 2, ...
        'Color', colors(i,:), ...
        'DisplayName', sprintf('Stage %d | Extension = %.1f mm', ...
        n(i), extension));
end

yl = ylim(ax);

shade = patch(ax, ...
    [b_min b_max b_max b_min], ...
    [yl(1) yl(1) yl(2) yl(2)], ...
    red, ...
    'FaceAlpha', 0.09, ...
    'EdgeColor', 'none', ...
    'HandleVisibility', 'off');

uistack(shade, 'bottom');

% Boundary lines
xline(ax, b_min, '--', ...
    'Color', coral, 'LineWidth', 1.5, ...
    'HandleVisibility', 'off');

xline(ax, b_max, '--', ...
    'Color', coral, 'LineWidth', 1.5, ...
    'HandleVisibility', 'off');

xlabel('Horizontal end-pin spacing, b (mm)');
ylabel('Scissor end-to-end height, h (mm)');
title('h(b) = n\sqrt(L_s^2 - b^2)');

xlim([0, Ls]);
xticks(0:10:Ls);
grid on;
box on;
hold off;

set(ax, ...
    'Color', ivory, ...
    'XColor', navy, ...
    'YColor', navy, ...
    'GridColor', grey, ...
    'GridAlpha', 0.5, ...
    'FontName', 'Arial', ...
    'FontSize', 11, ...
    'LineWidth', 1, ...
    'Layer', 'top');

set(get(ax,'Title'), 'Color', navy);
set(get(ax,'XLabel'), 'Color', navy);
set(get(ax,'YLabel'), 'Color', navy);

lgd = legend('show', ...
    'Location', 'southoutside', ...
    'Orientation', 'horizontal');
set(lgd, ...
    'Color', ivory, ...
    'TextColor', navy, ...
    'EdgeColor', grey);

exportgraphics(fig, 'Nscissor_fork_anlyse.png');
