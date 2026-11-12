% Planar kinematic animation of the wall-climbing drive train.
%
% One input disc carries two opposed pins that alternately index two
% 4-slot Geneva wheels:
%   Branch A (right): Geneva -> Z40/Z20 -> eccentric -> Scotch-yoke slider
%                     -> rocker -> Z32 pinion -> rack -> scissor height H
%   Branch B (up):    Geneva -> Z40/Z20 -> eccentric -> Scotch-yoke slider
%                     -> rocker + pawl -> ratchet / Z20 -> pad retraction q
%
% One input revolution (phi = 0..2*pi) gives four 90-degree stages:
%   1) scissor extension     (A indexes, B dwells)
%   2) lower-pad retraction  (B indexes, A dwells)
%   3) scissor contraction   (A indexes, B dwells)
%   4) lower-pad release     (B indexes, A dwells)
%
% Figure 1 shows the mechanism; Figure 2 plots H, velocity, acceleration
% and pad retraction against time, with markers synchronised to the animation.

% Figure 3 plots quasi-static input-shaft torque and tangential handle force.

clear; clc;

%%Paths
scriptFolder = fileparts(mfilename('fullpath'));
assetFolder  = fullfile('./animation_fusion');          % STL meshes (relative to pwd)
if ~isfolder(assetFolder)
    assetFolder = uigetdir(pwd, 'Choose animation_fusion');
    if isequal(assetFolder, 0), return; end
end

outFolder = fullfile(scriptFolder, 'renders');
if ~exist(outFolder, 'dir'), mkdir(outFolder); end

%% Timing / options
T   = 12;                           % duration of one input revolution, s
fps = 30;
t   = linspace(0, T, T*fps + 1);
phi = 2*pi*t/T;                     % input disc angle, rad

saveVideo    = true;
saveFigures  = true;
playRealtime = false;

%% Load meshes
files = {'Odisc.stl', 'Gdisc.stl', 'M1.5_Z40.stl', 'M1.5_Z20.stl', ...
         'M1.5_Z32.stl', 'M1_Z20.stl', 'ratchet_wheel.stl'};
% mesh{1} input disc   mesh{2} Geneva wheel   mesh{3} Z40   mesh{4} Z20
% mesh{5} A output Z32 mesh{6} B output Z20   mesh{7} ratchet wheel

for j = 1:numel(files)
    TR = stlread(fullfile(assetFolder, files{j}));
    mesh{j}.V = TR.Points;
    mesh{j}.F = TR.ConnectivityList;
end

%% Parameters
% Geneva drive (4-slot: pin radius r = C*sin(45 deg))
p.C   = 45;                         % input-to-Geneva centre distance, mm
p.r   = p.C/sqrt(2);                % drive pin radius, mm
p.R   = [30 20];                    % slider-pin rocker radii [A B], mm
p.rpA = 24;                         % pitch radius, A output pinion (M1.5 Z32), mm
p.rpB = 10;                         % pitch radius, B output gear (M1 Z20), mm

% Branch A: scissor lift. Height H = 2*sqrt(L^2 - b^2), b = pivot spacing.
p.L  = 145;                         % scissor link length, mm
p.b0 = sqrt(p.L^2 - 110^2);         % pivot spacing at H = 220 mm
sreq = (p.b0 - sqrt(p.L^2 - 140^2))/2;   % rack travel needed for H = 280 mm
p.bm = sreq/(2*p.rpA);              % rocker half-swing, rad
p.eA = p.R(1)*sin(p.bm);               % eccentricity giving +/- bm swing
p.deltaA = deg2rad(21);             % eccentric phase offset, branch A

% Branch B: pad retraction through pawl and ratchet
p.qmax    = 12;                     % nominal stroke before pawl take-up, mm
p.takeup  = .08;                    % assumed approach angle, rad; tune to hardware
p.bmB     = p.qmax/(2*p.rpB);       % nominal half-swing, rad
p.betaEng = -p.bmB + p.takeup;      % rocker angle at which the pawl engages
p.eB      = p.R(2)*sin(p.bmB);      % B eccentricity, mm; no take-up compensation

% Pawl geometry (in the rocker frame, origin at J)
p.lift      = deg2rad(30);          % pawl lift angle on the ramp
p.hingeR    = 46;                   % pawl hinge radius from J, mm
p.tipT      = -11;                  % tip tangential offset, mm
p.tipR      = sqrt(40^2 - p.tipT^2);   % keeps tip on ratchet radius 40 mm
p.tipLocal  = [p.tipR - p.hingeR, p.tipT];
p.tipOffset = atan2(p.tipT, p.tipR);
p.alphaEng  = pi/2 - p.betaEng;
p.wheelPhase = mod(p.alphaEng + p.tipOffset, 2*pi/60);   % 60-tooth ratchet

% Colours
p.blue   = [.22 .55 .71];
p.red    = [.79 .29 .29];
p.green  = [.33 .64 .54];
p.orange = [.85 .48 .18];

% Pivot positions in the local branch frame
p.E = [90 0];                       % Z20 / eccentric centre
p.J = [185 -p.R(1); 185 -p.R(2)];  % one pivot per branch; neutral slider pins at y = 0
branchAngle = [0 pi/2];             % A right, B up; no axial branch separation

%% Figure 1: mechanism
fig = figure('Color', 'w', 'Position', [55 55 900 970]);
ax  = axes(fig, 'Position', [.10 .10 .85 .80]);
hold(ax, 'on');
set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'ZColor', 'k');

% Shared input disc and its two opposed pins
driver  = part(ax, mesh{1}, [0 0 0], p.blue);
pinArms = plot3(ax, nan, nan, nan, 'b-', 'LineWidth', 2);
pins    = plot3(ax, nan, nan, nan, 'o', ...
                'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k');
a = linspace(0, 2*pi, 120);         % circle samples for eccentric discs

% Build the graphics for each branch
for j = 1:2
    angle = branchAngle(j);
    G = rot([p.C 0], angle);  E = rot(p.E, angle);  J = rot(p.J(j,:), angle);

    h(j).geneva = part(ax, mesh{2}, [G 0],   p.green);
    h(j).g40    = part(ax, mesh{3}, [G -13], p.blue);
    h(j).g20    = part(ax, mesh{4}, [E -13], p.red);
    if j == 1
        h(j).output  = part(ax, mesh{5}, [J -13], p.green);
    else
        h(j).output  = part(ax, mesh{6}, [J -13], p.green);
        h(j).ratchet = part(ax, mesh{7}, [J 1],   p.red);
    end

    % Static eccentric disc outline
    er = [p.eA p.eB];  rr = er(j) + 3;
    diskLocal = p.E + rr*[cos(a(:)) sin(a(:))];
    diskXY    = rot(diskLocal, angle);
    patch(ax, diskXY(:,1), diskXY(:,2), 12*ones(size(a)), p.red, ...
          'EdgeColor', 'k', 'FaceLighting', 'none');

    % Moving linkage elements (data filled in the animation loop)
    h(j).eccPin    = dot(ax, 'g');
    h(j).slotE     = ln(ax, 'k', 1);
    h(j).slotK     = ln(ax, 'k', 1);
    h(j).carriage  = ln(ax, 'b', 2);
    h(j).rocker    = ln(ax, 'r', 2);
    h(j).rockerPin = dot(ax, 'g');

    % Fixed pivots G, E, J
    plot3(ax, [G(1) E(1) J(1)], [G(2) E(2) J(2)], [8 14 14], ...
          'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 4);
end

% Input pivot and labels
plot3(ax, 0, 0, 8, 'ko', 'MarkerFaceColor', 'k');
text(ax,  82, -24, 20, 'A', 'FontSize', 14, 'Color', 'k');
text(ax, -23,  79, 20, 'B', 'FontSize', 14, 'Color', 'k');
text(ax, -24, -43, 20, 'Input', 'Color', 'k');

axis(ax, 'equal');
xlim(ax, [-55 235]);  ylim(ax, [-80 245]);  zlim(ax, [-20 25]);
view(ax, 0, 90);  camproj(ax, 'orthographic');  grid(ax, 'on');
xlabel(ax, 'X (mm)');  ylabel(ax, 'Y (mm)');  rotate3d(ax, 'on');

% Pawl is shown only on the main structure (branch B).
mainPawl = makePawl(ax, p);
head = annotation(fig, 'textbox', [.055 .91 .90 .08], 'String', '', ...
                  'EdgeColor', 'none', 'Color', 'k', 'FontSize', 15, ...
                  'Interpreter', 'none');

%% Video setup
if saveVideo
    v = VideoWriter(fullfile(outFolder, 'geneva_planar.mp4'), 'MPEG-4');
    v.FrameRate = fps;
    v.Quality   = 95;
    open(v);
end

% Frames exported as stage snapshots (mid-stage and end of cycle)
snapshots = round([45 135 225 360]/360*(numel(t) - 1)) + 1;

%% Figure 2: height, velocity, acceleration and pad retraction versus time
% Sample on a dense grid so numerical derivatives resolve the Geneva
% acceleration steps at 0/90/180/270 deg.
phd = linspace(0, 2*pi, 7201);      % 0.05 deg spacing
Hd  = zeros(size(phd));
qd  = Hd;
for k = 1:numel(phd)
    [Hd(k), qd(k)] = kin(phd(k), p);
end
td = T * phd / (2*pi);                % dense sample times, seconds
vH = gradient(Hd, td);                % mm/s
aH = gradient(vH, td);                % mm/s^2

Y   = {Hd, vH, aH, qd};
lab = {'H (mm)', 'dH/dt (mm/s)', 'd^2H/dt^2 (mm/s^2)', 'q (mm)'};

f2 = figure('Color', 'w', 'Position', [970 55 600 970]);
theme(f2, 'light');
tiledlayout(f2, 4, 1, 'TileSpacing', 'compact');
for i = 1:4
    a2 = nexttile;
    hold(a2, 'on');  grid(a2, 'on');
    plot(a2, td, Y{i}, 'b-');
    xline(a2, T*[1 2 3]/4, ':');                     % stage boundaries
    cursor(i) = xline(a2, 0, 'r-');                   % moving cursor
    dotH(i)   = plot(a2, 0, Y{i}(1), 'ro', ...
                     'MarkerFaceColor', 'r');         % moving marker
    ylabel(a2, lab{i});
    xlim(a2, [0 T]);
    xticks(a2, linspace(0, T, 9));
end
xlabel(a2, 'Time, t (s)');

%% Figure 3: drive demand over one input-shaft revolution (Section 4.3.2)
% Both Geneva drives use the same assumed efficiency. The last factor covers
% the downstream linkage on A and the linkage with pawl drive on B.
etaGeneva = 0.90;
etaGearPair = 0.90;
etaA = etaGeneva * etaGearPair * 0.90;
etaB = etaGeneva * etaGearPair * 0.80;
handleReduction = 3;                % handle turns per input-shaft turn
handleEfficiency = 0.90;
handleRadius = 0.100;               % m

% Section 3.3: upper-module breakaway thrust evaluated across wall gaps.
wallGap = 160:0.1:260;              % mm
diamondLink = 130;                  % mm
padOffset = 15;                     % mm per side
width = wallGap - 2*padOffset;
springLength = sqrt((2*diamondLink)^2 - width.^2);
crossedRun = springLength/2 + 60;
crossedRise = sqrt(178^2 - crossedRun.^2);
muStatic = 0.60;
normalPreload = (1.78 + 0.070*(springLength - 88.90)).*width./springLength;
normalGain = (crossedRun./(2*crossedRise)).*width./springLength;
pushLoad = max((0.5*9.81 + 2*muStatic*normalPreload)./(1 + 2*muStatic*normalGain));
liftLoad = 1.5*9.81;                % N, lower assembly lifted in stage 3

% Quasi-static envelopes from virtual work. Absolute slopes treat the
% short overtravel portions as resisting motion at the same stage load.
extension = phd > 0 & phd < pi/2;
retraction = phd > pi/2 & phd < pi & qd > 0;
contraction = phd > pi & phd < 3*pi/2;
release = phd > 3*pi/2;
heightSlope = abs(gradient(Hd, phd));  % mm per input-shaft radian
padSlope = abs(gradient(qd, phd));
torqueA = zeros(size(phd));
torqueA(extension) = pushLoad*heightSlope(extension)/(1000*etaA);
torqueA(contraction) = liftLoad*heightSlope(contraction)/(1000*etaA);

% Section 3.4: each row is a pad displacement, each column a wall gap.
% Both racks move. Static holding has no displacement work at the shaft.
widthRetracted = width - 2*qd(retraction).';
lengthRetracted = sqrt((2*diamondLink)^2 - widthRetracted.^2);
rackForce = (6.56 + 0.210*(lengthRetracted - 90.20)).*widthRetracted./lengthRetracted;
worstRackForce = max(rackForce, [], 2).';
torqueB = zeros(size(phd));
torqueB(retraction) = 2*worstRackForce.*padSlope(retraction)/(1000*etaB);
torqueB(release) = NaN;             % spring return: pawl/ramp load not modelled
handleForce = (torqueA + torqueB)/(handleReduction*handleEfficiency*handleRadius);

angleDeg = rad2deg(phd);
f3 = figure('Color', 'w', 'Position', [100 90 860 610]);
theme(f3, 'light');
layout3 = tiledlayout(f3, 2, 1, 'TileSpacing', 'compact');
axTorque = nexttile(layout3);
axForce = nexttile(layout3);
loadAxes = [axTorque axForce];
for i = 1:2
    hold(loadAxes(i), 'on'); grid(loadAxes(i), 'on');
    xlim(loadAxes(i), [0 360]); xticks(loadAxes(i), 0:45:360);
    xregion(loadAxes(i), 270, 360, 'FaceColor', [.5 .5 .5], ...
        'FaceAlpha', 0.10, 'HandleVisibility', 'off');
    xline(loadAxes(i), [90 180 270], ':', 'HandleVisibility', 'off');
    loadCursor(i) = xline(loadAxes(i), 0, 'r-', 'HandleVisibility', 'off');
end
plot(axTorque, angleDeg, torqueA, 'Color', p.blue, 'LineWidth', 1.2, 'DisplayName', 'A: scissor');
plot(axTorque, angleDeg, torqueB, '--', 'Color', p.orange, 'LineWidth', 1.2, 'DisplayName', 'B: lower pads');
ylabel(axTorque, 'Input-shaft torque (N m)');
legend(axTorque, 'Location', 'northwest', 'AutoUpdate', 'off');
plot(axForce, angleDeg, handleForce, 'Color', p.green, 'LineWidth', 1.2);
ylabel(axForce, 'Tangential handle force (N)');
xlabel(axForce, 'Input-shaft angle, \phi (deg)');
text(axForce, 315, max(handleForce, [], 'omitnan')/2, ...
    {'Spring return','Load unmodelled'}, 'HorizontalAlignment', 'center');
loadSeries = [torqueA; torqueB; handleForce];
markerAxes = [axTorque axTorque axForce];
markerColors = [p.blue; p.orange; p.green];
for i = 1:3
    loadDot(i) = plot(markerAxes(i), 0, loadSeries(i,1), 'o', ...
        'Color', markerColors(i,:), 'MarkerFaceColor', markerColors(i,:), ...
        'HandleVisibility', 'off');
end
frameLoads = interp1(phd, loadSeries.', phi).';
if saveVideo
    loadVideo = VideoWriter(fullfile(outFolder, 'drive_demand_cycle.mp4'), 'MPEG-4');
    loadVideo.FrameRate = fps;
    open(loadVideo);
end

%% Animation loop
try
    for k = 1:numel(t)
        if ~isgraphics(fig), break; end
        ph = phi(k);

        %  Geneva index angles (each wheel indexes twice per rev) 
        ga = index(ph, 0,      p) + index(ph, pi,     p);
        gb = index(ph, pi/2,   p) + index(ph, 3*pi/2, p);
        gs = [ga gb];

        % Eccentric angle (Z40 -> Z20 doubles the Geneva rotation)
        chi = [pi + p.deltaA + 2*ga, pi + 2*gb];

        % Scotch-yoke slider x = e*cos(chi) drives rocker: sin(beta) = x/R
        es   = [p.eA p.eB];
        beta = asin(es./p.R.*cos(chi));

        %  Input disc and pins 
        % One shared input disc and one shared pair of opposed pins.
        lambda = ph - pi/4;
        move(driver, mesh{1}.V, lambda - pi/2, [0 0 0]);
        pin = p.r*[cos(lambda) sin(lambda)];
        lineData(pinArms, [pin; 0 0; -pin], 7);
        lineData(pins,    [pin; -pin],      8);

        % Branch B output: pawl drives only after the take-up angle
        q = p.rpB*max(0, beta(2) - p.betaEng);
        q = min(p.qmax, q);
        outputB = -q/p.rpB;          % output gear / ratchet rotation, rad

        % Update both branches
        for j = 1:2
            angle = branchAngle(j);
            G = rot([p.C 0], angle);  E = rot(p.E, angle);  J = rot(p.J(j,:), angle);

            % Gears (Z40 is coaxial with Geneva; Z20 turns -2x)
            move(h(j).geneva, mesh{2}.V, angle - gs(j),           [G 0]);
            move(h(j).g40,    mesh{3}.V, angle - gs(j),           [G -13]);
            move(h(j).g20,    mesh{4}.V, angle + 2*gs(j) + pi/20, [E -13]);

            % Output gears
            if j == 1
                move(h(j).output, mesh{5}.V, angle - beta(1) - p.bm, [J -13]);
            else
                move(h(j).output,  mesh{6}.V, angle + outputB, [J -13]);
                move(h(j).ratchet, mesh{7}.V, ...
                     angle + p.wheelPhase + outputB, [J 1]);
            end

            % Linkage: eccentric pin P, slider offset x, rocker tip K
            x = es(j)*cos(chi(j));
            P = p.E + es(j)*[cos(chi(j)) sin(chi(j))];
            K = p.J(j,:) + [x, p.R(j)*cos(beta(j))];

            lineData(h(j).eccPin,    rot(P, angle), 14);
            lineData(h(j).slotE,     rot(rect(p.E(1) + x, 0, 6, 48), angle), 13);
            lineData(h(j).slotK,     rot(rect(p.J(j,1) + x, 0, 6, 34), angle), 13);
            lineData(h(j).carriage,  rot([p.E + [x 0]; p.J(j,1) + x, 0], angle), 13);
            lineData(h(j).rocker,    rot([p.J(j,:); K], angle), 14);
            lineData(h(j).rockerPin, rot(K, angle), 15);
        end

        % Pawl
        % Ramp lift is linked to rocker approach, not to a separate clock.
        % u = 0 at rocker home (pawl fully lifted), u = 1 at engagement;
        % smoothstep 3u^2 - 2u^3 lowers the pawl gradually.
        approach = (beta(2) + p.bmB)/p.takeup;
        u    = min(1, max(0, approach));
        lift = p.lift*(1 - (3*u^2 - 2*u^3));
        alpha = pi/2 - beta(2);
        [P, H, Tail, Tip] = pawlPose(alpha, lift, p);
        drawPawl(mainPawl, P, H, Tail, Tip, alpha, pi/2, rot(p.J(2,:), pi/2), p);

        % Validate the actual pawl tip against a radial tooth face.
        if lift < 1e-10
            % Engaged: tip must sit on r = 40 and on a tooth face
            relative = mod(atan2(Tip(2), Tip(1)) - (p.wheelPhase + outputB) ...
                           + pi/60, pi/30) - pi/60;
            assert(abs(relative) < 1e-9 && abs(norm(Tip) - 40) < 1e-9);
        elseif u < .001
            % Fully lifted: visible clearance above the teeth
            assert(norm(Tip) > 41);
        end

        %  Stage label and outputs
        stage  = min(4, floor(ph/(pi/2)) + 1);
        stages = {'Scissor extension', 'Lower-pad retraction', ...
                  'Scissor contraction', 'Lower-pad release'};

        % Output values are calculated from this same animation frame.
        rackTravel    = p.rpA*(beta(1) + p.bm);
        pivotSpacing  = p.b0 - 2*rackTravel;
        scissorHeight = 2*sqrt(p.L^2 - pivotSpacing^2);

        stageName = stages{stage};
        if abs(ph - 2*pi) < 1e-10
            stageName = 'End of lower-pad release';
        end
        set(head, 'String', sprintf(['φ = %.0f° | %s\n' ...
            'H = %.2f mm | q = %.2f mm (modelled retraction per pad)'], ...
            rad2deg(ph), stageName, scissorHeight, q));

        % Sync Figure 2 marker and cursor
        for i = 1:4
            set(dotH(i), 'XData', t(k), 'YData', interp1(td, Y{i}, t(k)));
            cursor(i).Value = t(k);
        end

        for i = 1:2
            loadCursor(i).Value = rad2deg(ph);
        end
        for i = 1:3
            set(loadDot(i), 'XData', rad2deg(ph), 'YData', frameLoads(i,k));
        end
        drawnow;

        % Output frames
        if saveVideo
            writeVideo(v, getframe(fig));
            writeVideo(loadVideo, getframe(f3));
        end
        if saveFigures && any(k == snapshots)
            n = find(k == snapshots, 1);
            exportgraphics(fig, fullfile(outFolder, ...
                sprintf('stage_%c.png', 'a' + n - 1)), 'Resolution', 180);
            frames(n) = getframe(fig);
        end
        if playRealtime, pause(1/fps); end
    end
catch ME
    if saveVideo, close(v); close(loadVideo); end
    rethrow(ME);
end

if saveVideo, close(v); close(loadVideo); end

%% Final exports
% 2x2 montage of the four stage snapshots
if saveFigures && exist('frames', 'var') && numel(frames) == 4
    im = {frames.cdata};
    imwrite([im{1} im{2}; im{3} im{4}], fullfile(outFolder, 'four_stages.png'));
end

% Clean kinematic plot (hide the moving marker)
set(cursor, 'Visible', 'off');
set(dotH, 'Visible', 'off');
exportgraphics(f2, fullfile(outFolder, 'H_q_vs_phi.png'), 'Resolution', 180);

if saveFigures
    set([loadCursor loadDot], 'Visible', 'off');
    exportgraphics(f3, fullfile(outFolder, 'drive_demand_vs_phi.png'), 'Resolution', 240);
end
[peakForce, peakIndex] = max(handleForce, [], 'omitnan');
fprintf('Modelled peaks: A %.2f N m, B %.2f N m, handle %.2f N at %.1f deg\n', ...
    max(torqueA), max(torqueB, [], 'omitnan'), peakForce, angleDeg(peakIndex));

fprintf('Finished: %s\n', outFolder);

%%  Local functions


function h = part(ax, m, P, col)
% Draw an STL mesh m translated by P.
h = patch(ax, 'Faces', m.F, 'Vertices', m.V + P, 'FaceColor', col, ...
          'EdgeColor', 'none', 'FaceLighting', 'none');
end

function move(h, V, theta, P)
% Rotate mesh vertices V by theta about z, then translate by P.
R = [cos(theta) -sin(theta) 0;
     sin(theta)  cos(theta) 0;
     0           0          1];
set(h, 'Vertices', V*R' + P);
end

function P = rot(P, a)
% Rotate row-vector points P (N x 2) counter-clockwise by a.
P = P*[cos(a) sin(a); -sin(a) cos(a)];
end

function h = ln(ax, c, w)
% Empty line handle with colour c and width w.
h = plot3(ax, nan, nan, nan, 'Color', c, 'LineWidth', w);
end

function h = dot(ax, c)
% Empty marker handle with face colour c.
% Note: shadows MATLAB's built-in dot() inside this file.
h = plot3(ax, nan, nan, nan, 'o', 'MarkerFaceColor', c, 'MarkerEdgeColor', 'k');
end

function lineData(h, P, z)
% Set 2-D points P on a line/marker handle at constant height z.
set(h, 'XData', P(:,1), 'YData', P(:,2), 'ZData', z*ones(size(P,1), 1));
end

function P = rect(x, y, w, h)
% Closed rectangle outline centred at (x, y).
P = [x - w/2, y - h/2;
     x + w/2, y - h/2;
     x + w/2, y + h/2;
     x - w/2, y + h/2;
     x - w/2, y - h/2];
end

function g = index(phi, start, p)
% Geneva wheel rotation for one pin engagement starting at phi = start.
% Engagement lasts 90 deg of input; output goes 0 -> pi/2, constant outside.
u = min(max(phi - start, 0), pi/2);
lambda = u - pi/4;                  % pin angle relative to centre line
g = atan2(p.r*sin(lambda), p.C - p.r*cos(lambda)) + pi/4;
end

function h = makePawl(ax, p)
% Create graphics handles for the pawl, its arm, ramp and wheel marker.
h.arm    = ln(ax, 'r', 2);
h.marker = ln(ax, 'k', 1);
h.body   = patch(ax, 'XData', nan, 'YData', nan, 'ZData', nan, ...
                 'FaceColor', p.orange, 'EdgeColor', 'k', 'FaceLighting', 'none');
h.hinge  = dot(ax, 'w');
h.tail   = dot(ax, 'w');
h.tip    = dot(ax, 'g');
set(h.tip, 'MarkerSize', 4);
h.ramp   = patch(ax, 'XData', nan, 'YData', nan, 'ZData', nan, ...
                 'FaceColor', [.5 .6 .65], 'EdgeColor', 'k', 'FaceLighting', 'none');
end

function [P, H, Tail, Tip] = pawlPose(alpha, lift, p)
% Pawl outline P, hinge H, tail and tip in the output-gear frame.
% alpha: rocker direction; lift: extra pawl rotation about its hinge.
H     = p.hingeR*[cos(alpha) sin(alpha)];
local = [4 17; 7 16; 2 1; 5 -7; p.tipLocal; -3 -6; -1 0];
P     = H + rot(local,       alpha + lift);
Tail  = H + rot([5.5 16.5],  alpha + lift);
Tip   = H + rot(p.tipLocal,  alpha + lift);
end

function drawPawl(h, P, H, Tail, Tip, alpha, a, J, p)
% Transform the pawl into world coordinates (rotate by a, shift to J) and draw.
P = rot(P, a) + J;  H = rot(H, a) + J;
Tail = rot(Tail, a) + J;  Tip = rot(Tip, a) + J;

set(h.body, 'XData', P(:,1), 'YData', P(:,2), 'ZData', 15*ones(size(P,1), 1));
lineData(h.arm,   [J; H], 14);
lineData(h.hinge, H,      16);
lineData(h.tail,  Tail,   16);
lineData(h.tip,   Tip,    16);

% A fixed ramp at the tail's raised home position.
[~, ~, rampContact] = pawlPose(pi/2 + p.bmB, p.lift, p);
rampLocal = rampContact + [0 0; -7 0; -7 -7; 0 -4];
rampLocal = rot(rampLocal, a) + J;
set(h.ramp, 'XData', rampLocal(:,1), 'YData', rampLocal(:,2), ...
    'ZData', 14*ones(4, 1));

% A spoke makes the wheel's driven/held/return motion visible.
wheelAngle = p.wheelPhase - max(0, (pi/2 - alpha) - p.betaEng);
lineData(h.marker, rot([0 0; 32*cos(wheelAngle) 32*sin(wheelAngle)], a) + J, 9);
end

function [H, q] = kin(ph, p)
% Scissor height H (mm) and pad retraction q (mm) at input angle ph.
% Mirrors the calculations in the animation loop.
ga  = index(ph, 0, p)    + index(ph, pi, p);
gb  = index(ph, pi/2, p) + index(ph, 3*pi/2, p);
chi = [pi + p.deltaA + 2*ga, pi + 2*gb];
beta = asin([p.eA p.eB]./p.R.*cos(chi));

rackTravel = p.rpA*(beta(1) + p.bm);
b = p.b0 - 2*rackTravel;
H = 2*sqrt(p.L^2 - b^2);
q = min(p.qmax, p.rpB*max(0, beta(2) - p.betaEng));
end
