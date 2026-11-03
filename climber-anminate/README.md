# Climber animations (ManimGL)

These are explanatory animations with prescribed positions, not dynamic or
friction simulations. Geometry uses illustrative millimetres, a 350 mm wall gap,
and a fixed scale to scene coordinates. This differs from the 160–260 mm MATLAB
design study. Run commands from this folder.

## Environment

Use Python 3.12 and **ManimGL** (`manimlib`), not Manim Community Edition.
The interactive source contains a compatibility adjustment for ManimGL 1.7.2.
Rendering also requires a working OpenGL environment, FFmpeg for video, and an
available text font (`Arial Unicode MS` is currently requested by the scenes).
The portrait script directly imports NumPy and Pillow.

The existing `pyproject.toml` and `uv.lock` list no third-party dependencies.
They are retained unchanged and are not a complete rendering environment lock.
Install ManimGL, NumPy and Pillow in your chosen environment before running:

```sh
python -m pip install manimgl==1.7.2 numpy pillow
manimgl interactive_cycle.py InteractiveCycle
```

These setup instructions have not been tested in a fresh environment.

## Source files and outputs

| File / scene | Result |
| --- | --- |
| `interactive_cycle.py` / `InteractiveCycle` | Live 3D loop with a five-stage gait; 100 mm climb over 16 seconds, then a 1-second camera rise; interactive controls |
| `interactive_cycle.py` / `OrbitPreview` | Same cycle with automatic orbit during headless rendering |
| `interactive_cycle.py` / `PPTCycle` | One 17-second cycle with camera rise and no captions or controls |
| `interactive_cycle.py` / `PPTOrbit` | Caption-free version with one full orbit |
| `interactive_cycle.py` / `PPTTwoCycles` | Two caption-free cycles, 34 seconds in total |
| `relief_portrait.py` / `MechanicalPortrait` | Frozen 210-degree pose with a near-orthographic camera, transparent background, cropped content and a 50-pixel border; saves `mechanical_portrait_perspective.png` beside the script |

Interactive preview does not explicitly save a video. Use ManimGL's write flag
for export, for example:

```sh
manimgl interactive_cycle.py PPTCycle -w
manimgl interactive_cycle.py PPTTwoCycles -w
python relief_portrait.py
```

`custom_config.yml` places rendered media under `.runtime/render`, cache under
`.runtime/manim-cache`, and temporary files under `.runtime/temp`, with a default
30 fps camera. ManimGL chooses the video filename from the scene and CLI options;
look under the configured output directory for the result. Existing files in
`videos/` are earlier exports and are not inputs to the scripts.

Controls: left drag or arrow keys to orbit, scroll to zoom, Space to pause,
R to reset the view, W to show/hide the walls; middle/right drag pans the camera.
Support colours indicate prescribed clamp state, not calculated contact forces.

## Other files

- `custom_config.yml`: rendering directories and default frame rate; no media itself.
- `pyproject.toml`: project metadata and Python range; no media itself.
- `uv.lock`: existing project-only lock; no media itself.
- `.python-version`: selects Python 3.12 for compatible environment managers.
- `.gitignore`: excludes local Python environments and build artifacts.
- `README.md`: usage and output documentation; no generated media.

Submit source and needed configuration. The parent `.gitignore` excludes generated
images, video exports, rendering caches, environments and local editor settings.
Existing exported media were not translated or regenerated; rerender from the
English source to update text embedded in videos.
