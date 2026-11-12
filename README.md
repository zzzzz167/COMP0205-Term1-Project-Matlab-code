# Wall-Gap Climber: MATLAB Scripts

## Run

Open MATLAB in the repository root, then run:

```matlab
cd('Design_report');
run('diamond_length.m');             % Fig. 13
run('lower_diamond_force_anlyse.m');  % Fig. 14
run('upper_diamond_force_anlyse.m');  % Fig. 15
run('NScissor_fork_anlyse.m');         % Fig. 16
run('geneva_planar.m');              % Figs. 17, 18 and 20
run('lower_req.m');                  % Fig. 19
```

See [Design_report/README.md](Design_report/README.md) for the output files corresponding to each report figure.

Use MATLAB with support for `stlread`, `exportgraphics`, `tiledlayout`, `theme` and `xregion`. Video export requires MPEG-4 support. Scripts clear the workspace and overwrite existing outputs.

For the earlier pitch scripts, change into `Pitch/` and run the required `.m` file. Python animation instructions are in [Pitch/climber-anminate/README.md](Pitch/climber-anminate/README.md).
