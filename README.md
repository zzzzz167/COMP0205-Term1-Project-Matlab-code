# Wall-Gap Climber: MATLAB Models and Animations

Mechanism studies for COMP0205 Mechatronics and Making at UCL. The design
objective is approximately 500 mm cumulative climb between walls 160–260 mm apart.
The scripts are independent studies, not an integrated validated hardware model.

## MATLAB files and outputs

Run each script from this repository folder in MATLAB. Files are saved in the
**current MATLAB folder** and an existing file with the same name is overwritten.
The scripts clear workspace variables before running.

| File | Purpose and main inputs | What it generates |
| --- | --- | --- |
| `NScissor_fork_anlyse.m` | Compare 1, 2 and 3 stages; bar length 150 mm; selected horizontal spacing 40–90 mm | Figure of height versus spacing, shaded travel range and extension values; `Nscissor_fork_anlyse.png` |
| `Scissor_fork_motion.m` | Two-stage scissor; bar length 2 in consistent arbitrary length units; slider speed 0.2 units/s | Animated figure; `scissor_fork_motion.mp4` if `record = true` |
| `rhombus_motion.m` | Rhombus with 0.150 m sides; imposed vertical speed 0.05 m/s | Animated linkage and decorative spring; `rhombus_motion.mp4` if `record = true` |
| `rhombus_motion_anlyse.m` | Side lengths 110–160 mm; pad offset 15 mm on each side | Width versus diagonal plot with 160/260 mm reference lines; `rhombus_motion_anlyse.png` at 300 dpi |
| `rhombus_force_anlyse.m` | Side lengths 130/140 mm; four candidate springs; mass 2 kg; reference friction coefficient 0.4 | Four-panel plot of normal force per wall and required static friction versus wall gap; `rhombus_force_anlyse.png` at 300 dpi |

Example: `run('rhombus_force_anlyse.m')`. These scripts use MATLAB graphics and
`VideoWriter`; no additional toolbox calls were identified. Use a release
supporting `exportgraphics` (R2020a or later); exact release compatibility has
not been tested. MPEG-4 export also depends on platform support.

Set `record = false` for animation without video export. Both MATLAB animations
use `dt = 0.05` s but export at 25 frames/s, so the exported video plays faster
than simulated time. The variable `cycle` sets the simulated time horizon;
travel margins mean it need not equal the number of visible oscillations.

## Assumptions

Geometry assumes rigid bars and ideal pins. The force study uses initial spring
tension plus linear extension force, ideal force transfer, and symmetric contact
at two walls. Invalid geometry or spring lengths are omitted using NaN. It does
not include dynamics, joint friction, structural deformation or a safety factor.
Spring data must be checked against supplier specifications before hardware use.

## Python animation files

The optional `climber-anminate/` folder contains explanatory ManimGL scenes.
See its [README](climber-anminate/README.md) for every scene, outputs and commands.
These animations use a **350 mm illustrative wall gap** and prescribed motion;
their 100 mm rise are separate visual scenarios from the MATLAB studies.
