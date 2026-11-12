% Animate an ideal two-stage scissor driven by a horizontal slider at A.
% L is the diagonal bar length; positions use a consistent arbitrary length
% unit and vAS uses that unit per second. B remains fixed at the origin.
% Output: scissor_fork_motion.mp4 when record is true; otherwise figure only.

clear; clc;
record = true;

vAS = 0.2;
L = 2;

cycle = 1;
T = cycle * 2 * L / vAS;
dt = 0.05;
t = 0:dt:T;

ivory = [250 249 246]/255;
red   = [179 20 36]/255;
navy  = [36 50 61]/255;
teal  = [64 111 116]/255;
grey  = [210 207 202]/255;


vA = zeros(size(t));
vA(1) = vAS;
pA = zeros(numel(t),2);
pA(1,:) = [1 0];
pB = zeros(numel(t),2);

% Reverse the prescribed slider speed near each travel limit.
% These margins avoid the fully folded or extended singular configurations.
for k = 1:numel(t) - 1
    if pA(k,1) >= (L-0.05) || pA(k,1) <= (pB(1) + 0.05)
        vA(k+1) = -vA(k);
    else
        vA(k+1) = vA(k);
    end

    pA(k+1, 1) = pA(k, 1) + vA(k+1) * dt;
end

% Each stage has the same height; crossing pivots lie at bar midpoints.
H = sqrt(L^2 - pA(:,1).^2);
pD = [pB(:,1) H];
pC = [pA(:,1) H];
pE = [pA(:,1) 2*H];
pF = [pB(:,1) 2*H];
pJA = [(pA(:,1) + pB(:,1))/2 1/2 * H];
pJB = [(pA(:,1) + pB(:,1))/2 (1/2+1) * H];


figure('Color', ivory);
sliderW = 0.24;
sliderH = 0.14;

plot(pB(1,1), pB(1,2), 'o', ...
    'Color', navy, 'MarkerFaceColor', navy);
hold on;

A = plot(pA(1,1), pA(1,2), 'o', ...
    'Color', navy, 'MarkerFaceColor', navy);
D = plot(pD(1,1), pD(1,2), 'o', ...
    'Color', navy, 'MarkerFaceColor', navy);
C = plot(pC(1,1), pC(1,2), 'o', ...
    'Color', navy, 'MarkerFaceColor', navy);
E = plot(pE(1,1), pE(1,2), 'o', ...
    'Color', navy, 'MarkerFaceColor', navy);
F = plot(pF(1,1), pF(1,2), 'o', ...
    'Color', navy, 'MarkerFaceColor', navy);
JA = plot(pJA(1,1), pJA(1,2), 'o', ...
    'Color', navy, 'MarkerFaceColor', navy);
JB = plot(pJB(1,1), pJB(1,2), 'o', ...
    'Color', navy, 'MarkerFaceColor', navy);

AD = plot([pA(1,1) pD(1,1)], [pA(1,2) pD(1,2)], ...
    '-', 'Color', red, 'LineWidth', 2);
BC = plot([pB(1,1) pC(1,1)], [pB(1,2) pC(1,2)], ...
    '-', 'Color', red, 'LineWidth', 2);
DE = plot([pD(1,1) pE(1,1)], [pD(1,2) pE(1,2)], ...
    '-', 'Color', red, 'LineWidth', 2);
CF = plot([pC(1,1) pF(1,1)], [pC(1,2) pF(1,2)], ...
    '-', 'Color', red, 'LineWidth', 2);

sliderA = rectangle( ...
    'Position', [pA(1,1)-sliderW/2, ...
    pA(1,2)-sliderH/2, ...
    sliderW, sliderH], ...
    'FaceColor', teal, ...
    'EdgeColor', navy, ...
    'LineWidth', 1.5, ...
    'Curvature', [0.1 0.1]);

axis equal;
axis([-0.2 L*1.3 -0.5 2*L*1.3]);

xlabel('x');
ylabel('y');
grid on;


ax = gca;
set(ax, ...
    'Color', ivory, ...
    'XColor', navy, ...
    'YColor', navy, ...
    'GridColor', grey, ...
    'GridAlpha', 0.4);


% Export one frame per time sample. Playback uses FrameRate, not dt;
% changing either independently changes video speed relative to model time.
if record
    v = VideoWriter("scissor_fork_motion.mp4", 'MPEG-4');
    v.FrameRate = 25;
    open(v);
end


% Reuse graphics handles rather than creating new objects at every frame.
for k = 1:numel(t)
    set(A, 'XData', pA(k,1), 'YData', pA(k,2));
    set(D, 'XData', pD(k,1), 'YData', pD(k,2));
    set(C, 'XData', pC(k,1), 'YData', pC(k,2));
    set(E, 'XData', pE(k,1), 'YData', pE(k,2));
    set(F, 'XData', pF(k,1), 'YData', pF(k,2));
    set(JA, 'XData', pJA(k,1), 'YData', pJA(k,2));
    set(JB, 'XData', pJB(k,1), 'YData', pJB(k,2));

    set(AD, 'XData', [pA(k,1) pD(k,1)], ...
        'YData', [pA(k,2) pD(k,2)]);
    set(BC, 'XData', [pB(k,1) pC(k,1)], ...
        'YData', [pB(k,2) pC(k,2)]);
    set(DE, 'XData', [pD(k,1) pE(k,1)], ...
        'YData', [pD(k,2) pE(k,2)]);
    set(CF, 'XData', [pC(k,1) pF(k,1)], ...
        'YData', [pC(k,2) pF(k,2)]);

    set(sliderA, 'Position', ...
        [pA(k,1)-sliderW/2, ...
        pA(k,2)-sliderH/2, ...
        sliderW, sliderH]);

    drawnow;

    if record
        writeVideo(v, getframe(gcf));
    end

    pause(dt);
end

if record
    close(v);
end
