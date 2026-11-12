# Design Report: Run Instructions and Figure Mapping

## Run

Set MATLAB's current folder to `Design_report/`, then run any script independently, for example:

```matlab
run('lower_diamond_force_anlyse.m');
run('geneva_planar.m');
```

Keep `animation_fusion/` in this folder: `geneva_planar.m` reads its STL files from that location. It saves outputs in `renders/`; the other scripts save PNGs in the current MATLAB folder. Existing outputs are overwritten.

In `geneva_planar.m`, set `saveVideo = false` to skip video export. Keep `saveFigures = true` to export the report figures. The script also generates `renders/geneva_planar.mp4` and `renders/drive_demand_cycle.mp4` when video export is enabled.

Use MATLAB with support for `stlread`, `exportgraphics`, `tiledlayout`, `theme` and `xregion`. MPEG-4 support is needed only for video export.

## Report Figures

Figure numbers refer to the supplied `main.pdf`.

| Figure | Content | Script | Output file |
|---|---|---|---|
| Fig. 13 | Diamond link-length comparison | `diamond_length.m` | `diamond_length.png` |
| Fig. 14 | Lower-clamp spring comparison | `lower_diamond_force_anlyse.m` | `lower_diamond_force_anlyse.png` |
| Fig. 15 | Upper-clamp holding and upward starting force | `upper_diamond_force_anlyse.m` | `upper_diamond_force_anlyse.png` |
| Fig. 16 | Scissor stage-count comparison | `NScissor_fork_anlyse.m` | `Nscissor_fork_anlyse.png` |
| Fig. 17 | Four transmission stages | `geneva_planar.m` | `renders/four_stages.png` |
| Fig. 18 | Scissor kinematics and lower-pad retraction | `geneva_planar.m` | `renders/H_q_vs_phi.png` |
| Fig. 19 | Lower-clamp grip margin | `lower_req.m` | `lower_clamp_force_check.png` |
| Fig. 20 | Input-shaft torque and handle force | `geneva_planar.m` | `renders/drive_demand_vs_phi.png` |

For Fig. 17, individual panels are saved as `renders/stage_a.png` through `renders/stage_d.png`. Despite its filename, `H_q_vs_phi.png` uses time in seconds on the horizontal axis.
