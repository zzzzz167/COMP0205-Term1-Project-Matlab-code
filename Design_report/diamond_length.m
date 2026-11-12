% Compare overall clamp width against the rhombus diagonal s.
% All lengths are in mm. Ideal rigid links give w = sqrt(4*L^2-s^2)+2*e.
% The 160 and 260 mm lines mark the target wall-gap range.

clear; clc;

L = [110 120 130, 140, 150, 160];
e = 15;  % Horizontal offset from each hinge to its contact surface (mm)

ivory = [250 249 246]/255;
red   = [179 20 36]/255;
navy  = [36 50 61]/255;
teal  = [64 111 116]/255;
gold  = [161 116 54]/255;
grey  = [210 207 202]/255;
coral  = [205 104 92]/255;
plum   = [116 102 131]/255;

colors = [red; navy; teal; gold; coral; plum];

fig = figure;
hold on;

for i = 1:numel(L)
    Lc = L(i);

    % Full ideal geometric range, including the limiting configurations
    s = linspace(0, 2*Lc, 500);

    % Overall width across the outer faces of both contact pads
    w = sqrt(max(0, 4*Lc^2 - s.^2)) + 2*e;

    plot(s, w, 'LineWidth', 2, ...
        'Color', colors(i,:), ...
        'DisplayName', sprintf('L = %d mm', Lc));
end

yline(160, '--', '160 mm', ...
    'Color', red, 'LineWidth', 1.5, ...
    'HandleVisibility', 'off');

yline(260, '--', '260 mm', ...
    'Color', red, 'LineWidth', 1.5, ...
    'HandleVisibility', 'off');

xlabel('Spring attachment spacing, l=AC (mm)');
ylabel('Overall pad width (mm)');

xlim([0, 2*max(L)]);
lgd = legend('show', 'Location', 'best');
grid on;
box on;
hold off;

ax = gca;

set(get(ax, 'Title'), 'Color', navy);
set(get(ax, 'XLabel'), 'Color', navy);
set(get(ax, 'YLabel'), 'Color', navy);

exportgraphics(fig, 'diamond_length.png', 'Resolution', 300);
