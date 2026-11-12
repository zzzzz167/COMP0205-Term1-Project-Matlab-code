% Animate a four-link rhombus with A fixed and C moving vertically.
% L is each side length (m); vCS is the imposed speed of C (m/s).
% Motion is prescribed kinematically; the drawn spring does not drive it.
% Output: rhombus_motion.mp4 when record is true; otherwise figure only.

clear; clc;
record = true;

vCS = 0.05;
L = 150e-3;

cycle = 6;
T = cycle * 2 * L / vCS;
dt = 0.05;
t = 0:dt:T;

vC = zeros(size(t));
vC(1) = vCS;
pC = zeros(numel(t),2);
pC(1,:) = [0 sqrt(2*L^2)];

pA = zeros(numel(t),2);

% Reverse the prescribed slider speed near each travel limit.
% These margins avoid the fully folded or extended singular configurations.
for k = 1:numel(t) - 1
    if pC(k,2) >= (2*L-0.05) || pC(k,2) <= (pA(1,2) + 0.05)
        vC(k+1) = -vC(k);
    else
        vC(k+1) = vC(k);
    end

    pC(k+1, 2) = pC(k, 2) + vC(k+1) * dt;
end

% The squared diagonals sum to 4*L^2; B and D sit at half-height.
Y = sqrt(4*L^2 - pC(:,2).^2);
pD = [-Y/2 (pC(:,2) + pA(:,2))/2];
pB = [Y/2 (pC(:,2) + pA(:,2))/2];

springWidth = 0.008;
springTurns = 10;
s = linspace(0, 1, 200);
springX = [0, 0, ...
    springWidth * sin(2*pi*springTurns*s), 0, 0];

springY = [0, 0.12, ...
    0.12 + 0.76*s, 0.88, 1];

red   = [179 20 36]/255;
ivory = [250 249 246]/255;
navy  = [36 50 61]/255;
springColor = navy;


figure('Color', ivory);


plot(pA(1,1), pA(1,2), 'o', ...
    'Color', navy, 'MarkerFaceColor', navy);

hold on;
set(gca, 'Color', ivory, 'XColor', navy, 'YColor', navy);

B = plot(pB(1,1), pB(1,2), 'o', ...
    'Color', navy, 'MarkerFaceColor', navy);
C = plot(pC(1,1), pC(1,2), 'o', ...
    'Color', navy, 'MarkerFaceColor', navy);
D = plot(pD(1,1), pD(1,2), 'o', ...
    'Color', navy, 'MarkerFaceColor', navy);

AD = plot([pA(1,1) pD(1,1)], [pA(1,2) pD(1,2)], ...
    '-', 'Color', red, 'LineWidth', 2);
AB = plot([pA(1,1) pB(1,1)], [pA(1,2) pB(1,2)], ...
    '-', 'Color', red, 'LineWidth', 2);
BC = plot([pB(1,1) pC(1,1)], [pB(1,2) pC(1,2)], ...
    '-', 'Color', red, 'LineWidth', 2);
DC = plot([pD(1,1) pC(1,1)], [pD(1,2) pC(1,2)], ...
    '-', 'Color', red, 'LineWidth', 2);

spring = plot(springX, pC(1,2)*springY, ...
    'Color', springColor, 'LineWidth', 1.8);

axis equal;
axis([-L*1.3 L*1.3 -0.13 2*L*1.3]);
grid on;
xlabel('x');
ylabel('y');

% Export one frame per time sample. Playback uses FrameRate, not dt;
% changing either independently changes video speed relative to model time.
if record
    v = VideoWriter("rhombus_motion.mp4", 'MPEG-4');
    v.FrameRate =25;
    open(v);
end

% Reuse graphics handles rather than creating new objects at every frame.
for k = 1:numel(t)

    set(C, 'XData', pC(k,1), 'YData', pC(k,2));
    set(B, 'XData', pB(k,1), 'YData', pB(k,2));
    set(D, 'XData', pD(k,1), 'YData', pD(k,2));

    set(AD, 'XData', [pA(k,1) pD(k,1)], 'YData', [pA(k,2) pD(k,2)]);
    set(AB, 'XData', [pA(k,1) pB(k,1)], 'YData', [pA(k,2) pB(k,2)]);
    set(BC, 'XData', [pB(k,1) pC(k,1)], 'YData', [pB(k,2) pC(k,2)]);
    set(DC, 'XData', [pD(k,1) pC(k,1)], 'YData', [pD(k,2) pC(k,2)]);

    set(spring, 'YData', pC(k,2)*springY);

    drawnow;

    if record
        writeVideo(v, getframe(gcf));
    end

    pause(dt);
end

if record
    close(v);
end
