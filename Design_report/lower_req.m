clc;clear;

L = 130;
L_a = 178;
a = 60;
mLower = 1.5;
mUpper =0.5;
g = 9.81;

muAssumed = 0.60;
wallGap = linspace(160, 260, 1001);
offset=15;

springFreeLength = [90.2 88.9];
springRate = [0.21 0.07];
springInitialTension = [6.56 1.78];
springMaxLength = [258.19 335.94];

w = wallGap-2*offset;
l = 2*L*sqrt(1- (w / (2 * L)).^2);
h = sqrt(L_a^2 - (l./2+a).^2);

N_l = (springRate(1)*(l-springFreeLength(1))+springInitialTension(1)) .* (w./l);
f_l = 2*muAssumed * N_l;

N_u = (springRate(2)*(l-springFreeLength(2))+springInitialTension(2)) .* (w./l);
f_u = 2*muAssumed * N_u;

U_start = (mUpper*g + f_u) ./ (1+muAssumed* ((l./2+a)./h) .*(w./l));

F_check = f_l-(mLower*g + U_start);

F_required = mLower*g + U_start;
[minMargin, idx] = min(F_check);
Dcrit = wallGap(idx);

fig = figure('Color', 'w');
theme(fig, "light");
hold on;
plot(wallGap, f_l, 'b-', 'LineWidth', 1.8, ...
    'DisplayName', 'Available friction force');
plot(wallGap, F_required, 'r--', 'LineWidth', 1.8, ...
    'DisplayName', 'Required support force');

% 用竖线连接同一墙距下的两个力，标出最小余量
plot([Dcrit Dcrit], [F_required(idx) f_l(idx)], 'ko-', ...
    'LineWidth', 1.3, 'MarkerFaceColor', 'k', ...
    'HandleVisibility', 'off');
text(Dcrit + 2, (F_required(idx) + f_l(idx))/2, ...
    sprintf('Minimum margin: %.2f N', minMargin), ...
    'VerticalAlignment', 'middle');

xlabel('Wall gap (mm)');
ylabel('Vertical force (N)');
xlim([158 262]);   % 两端留白，让 160 mm 处的标记清楚可见
legend('Location', 'best');
grid on;
box on;

exportgraphics(gcf, 'lower_clamp_force_check.png', 'Resolution', "300");