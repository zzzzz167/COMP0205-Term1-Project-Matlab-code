% Initial stage comparison using 150 mm rigid links and ideal pins.
% The shaded interval is the change in total bottom-pin spacing, b.
clc; clear;

n = [1 2 3];
Ls = 150;                       % End-to-end pin spacing of one link (mm)
b = 0:0.1:Ls;
b_min = 40;
b_max = 90;
h = sqrt(Ls^2 - b.^2);          % Height of one stage (mm)

%curve colours for one, two and three stages, respectively.
curveColours = [36 50 61; 179 20 36; 64 111 116] / 255;

fig = figure('Position', [100 100 820 490]);
theme(fig, 'light');
ax = axes(fig);
hold(ax, 'on');

xregion(ax, b_min, b_max, 'HandleVisibility', 'off');
xline(ax, b_min, '--', 'HandleVisibility', 'off');
xline(ax, b_max, '--', 'HandleVisibility', 'off');

for i = 1:numel(n)
    H = n(i) * h;
    stroke = interp1(b, H, b_min) - interp1(b, H, b_max);
    plot(ax, b, H, 'Color', curveColours(i,:), 'LineWidth', 2, ...
        'DisplayName', sprintf('n = %d (stroke %.1f mm)', n(i), stroke));
end

xlabel(ax, 'Horizontal end-pin spacing, b (mm)');
ylabel(ax, 'Total scissor height, H (mm)');
xlim(ax, [0 Ls]);
xticks(ax, 0:10:Ls);
grid(ax, 'on');
box(ax, 'on');
legend(ax, 'Location', 'southoutside', 'Orientation', 'horizontal');
hold(ax, 'off');

exportgraphics(fig, 'Nscissor_fork_anlyse.png', 'Resolution', 300);
