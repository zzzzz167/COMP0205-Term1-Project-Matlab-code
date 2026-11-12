"""ManimGL: manimgl interactive_cycle.py InteractiveCycle (interactive, continuous loop)."""

import math

from manimlib import (
    DEG,
    DOWN,
    ORIGIN,
    TAU,
    UP,
    Group,
    Line,
    ParametricSurface,
    Polygon,
    Text,
    ThreeDScene,
    ValueTracker,
    VGroup,
    VMobject,
    always_redraw,
    np,
)

# Presentation palette: warm ivory, crimson, charcoal, warm neutral metal.
PALETTE = dict(
    background="#FAF9F6",
    primary="#B31324",
    ink="#171717",
    scissor="#514B48",
    metal="#A59C92",
    pin="#D8D3CC",
    wall="#8CA6B5",
    muted="#111111",
    released="#B7AFA6",
)

# One complete gait; shared by playback, camera tracking, and video export.
CYCLE_SECONDS = 16.0
CAMERA_MOVE_SECONDS = 1.0
PLAYBACK_CYCLE_SECONDS = CYCLE_SECONDS + CAMERA_MOVE_SECONDS
CLIMB_PER_CYCLE = 100.0

STOPS = [0, 60, 150, 210, 255, 360]
PHASES = ["Lower clamp closes", "Scissor extends", "Upper clamp closes", "Lower clamp releases", "Scissor retracts"]


def smooth(t):
    """Clamp and ease a phase fraction with zero endpoint velocity/acceleration."""
    t = max(0.0, min(1.0, t))
    return t * t * t * (10 + t * (-15 + 6 * t))


def playback_state(elapsed):
    """Climb with a stationary camera, then pause and raise the camera."""
    turn, within = divmod(max(0.0, elapsed), PLAYBACK_CYCLE_SECONDS)
    phase = 360 * (turn + min(within / CYCLE_SECONDS, 1.0))
    reframing = within >= CYCLE_SECONDS
    follow = CLIMB_PER_CYCLE * (
        turn + smooth((within - CYCLE_SECONDS) / CAMERA_MOVE_SECONDS)
    )
    return phase, follow, reframing


def state(phi):
    """Five-stage gait, starting with the upper end supporting the mechanism.

    The first stage closes the lower end before releasing the upper end.
    This support handoff belongs to stage 1; there is no sixth stage.
    Input phi is cumulative crank angle in degrees. Lengths are illustrative mm.
    Return lower Z, upper Z, stage, lower width, upper width, support flags.
    Support flags reflect prescribed pad contact, not a solved friction model.
    """
    turn = int(phi // 360)
    angle = phi % 360
    k = next((i for i in range(5) if angle < STOPS[i + 1]), 4)
    t = (angle - STOPS[k]) / (STOPS[k + 1] - STOPS[k])
    f = smooth(t)
    lower = turn * CLIMB_PER_CYCLE
    upper = lower + 525
    lower_width, upper_width = 350.0, 277.0
    if k == 0:
        lower_width = 277 + 73 * smooth(t / 0.55)
        upper_width = 350 - 73 * smooth((t - 0.65) / 0.35)
    elif k == 1:
        upper += CLIMB_PER_CYCLE * f
    elif k == 2:
        upper += CLIMB_PER_CYCLE
        upper_width = 277 + 73 * f
    elif k == 3:
        upper += CLIMB_PER_CYCLE
        upper_width = 350
        lower_width = 350 - 73 * f
    else:
        upper += CLIMB_PER_CYCLE
        lower += CLIMB_PER_CYCLE * f
        upper_width, lower_width = 350.0, 277.0
    lower_locked = lower_width >= 350 - 1e-7
    upper_locked = upper_width >= 350 - 1e-7
    return lower, upper, k, lower_width, upper_width, lower_locked, upper_locked


class InteractiveCycle(ThreeDScene):
    default_frame_orientation = (-25, 68)
    drag_to_pan = False
    preview_orbit = False
    presentation_mode = False
    render_cycles = 1

    def construct(self):
        # ManimGL 1.7.2 leaves CLI --fps as text; timing needs a number.
        self.camera.fps = int(self.camera.fps)
        self.camera.background_rgba = np.array([250 / 255, 249 / 255, 246 / 255, 1.0])
        self.paused = False
        clock = ValueTracker(0)
        self.cycle_clock = clock
        self.frame.reorient(-25, 68).set_height(8)
        self.playback_time = 0.0
        self.camera_follow_height = 0.0
        self.camera_reframing = False

        def advance_cycle(m, dt):
            if self.paused:
                return
            self.playback_time += dt
            phase, follow, self.camera_reframing = playback_state(self.playback_time)
            m.set_value(phase)
            # Shift the real camera only between gaits. User pan/orbit is preserved.
            self.frame.shift(0.007 * np.array([0, 0, follow - self.camera_follow_height]))
            self.camera_follow_height = follow

        clock.add_updater(advance_cycle)
        self.add(clock)

        def label(s, size=24, color=PALETTE["ink"]):
            return Text(
                s, font="Arial Unicode MS", font_size=size, color=color, stroke_width=0
            ).fix_in_frame()

        # True 3D world coordinates: horizontal XY diamonds and central XZ scissors.
        def p(x, y, z):
            # Fixed world coordinates: the mechanism climbs against stationary walls.
            return 0.007 * np.array([x, y, z - 300])

        title = label("Interactive 3D cycle", 32).to_edge(UP)
        subtitle = label(
            "Drag to orbit | Scroll to zoom | Space: pause | R: reset",
            18,
            color=PALETTE["muted"],
        ).next_to(title, DOWN, buff=0.15)
        self.walls_visible = True

        def wall_geometry():
            walls = Group()
            opacity = 1 if self.walls_visible else 0
            # Extend only the unseen top; the wall bottom and seams stay fixed.
            top = max(900, clock.get_value() / 360 * CLIMB_PER_CYCLE + 900)
            # This ManimGL version does not invalidate cached camera matrices
            # when only orientation changes (mouse drag or orbit).
            self.frame.note_changed_data()
            camera = self.frame.get_implied_camera_location()
            # Transparent triangle surfaces are drawn after opaque geometry,
            # far wall first, while retaining the mechanism's depth buffer.
            sides = sorted(
                [-175, 175],
                key=lambda x: np.linalg.norm(p(x, 0, 400) - camera),
                reverse=True,
            )
            for x in sides:
                surface = ParametricSurface(
                    lambda u, v, x=x, top=top: p(x, -280 + 560 * u, -100 + (top + 100) * v),
                    resolution=(2, 2),
                    color=PALETTE["wall"],
                    opacity=0.12 * opacity,
                    shading=(0, 0, 0),
                    depth_test=True,
                )
                corners = [p(x, -280, -100), p(x, 280, -100),
                           p(x, 280, top), p(x, -280, top)]
                # Bias guide lines very slightly toward the viewer to avoid
                # fighting the wall's own depth at the same plane.
                bias = np.array([np.sign(camera[0] - p(x, 0, 0)[0]) * 0.0001, 0, 0])
                edges = VGroup(*[
                    Line(corners[i] + bias, corners[(i + 1) % 4] + bias,
                         stroke_color=PALETTE["wall"],
                         stroke_opacity=0.65 * opacity, stroke_width=1)
                    .apply_depth_test()
                    for i in range(4)
                ])
                first_seam = max(0, int(self.camera_follow_height // 200) * 200 - 400)
                for z in range(first_seam, int(top) + 1, 200):
                    edges.add(Line(
                        p(x, -280, z) + bias, p(x, 280, z) + bias,
                        stroke_color=PALETTE["wall"],
                        stroke_opacity=0.25 * opacity, stroke_width=0.6,
                    ).apply_depth_test())
                walls.add(Group(surface, edges))
            return walls

        walls = always_redraw(wall_geometry)
        self.wall_guides = walls
        if not self.presentation_mode:
            self.add(title, subtitle)

        def prism(vertices, offset, color):
            # Use real triangle surfaces, not vector-fill polygons: the shared GPU
            # depth buffer must choose the visible face at every pixel.
            v = [np.array(t, dtype=float) for t in vertices]
            off = np.array(offset, dtype=float)
            faces = [v[::-1], [t + off for t in v]]
            for i in range(len(v)):
                j = (i + 1) % len(v)
                faces.append([v[i], v[j], v[j] + off, v[i] + off])
            out = Group()
            for face in faces:
                a, b, c, d = [p(*t) for t in face]
                out.add(
                    ParametricSurface(
                        lambda u, w, a=a, b=b, c=c, d=d: (
                            (1 - u) * (1 - w) * a
                            + u * (1 - w) * b
                            + u * w * c
                            + (1 - u) * w * d
                        ),
                        resolution=(2, 2),
                        color=color,
                        opacity=1,
                        shading=(0.18, 0.22, 0.06),
                        depth_test=True,
                    )
                )
            return out

        def beam(a, b, width, thick, color, plane="xy"):
            a, b = np.array(a, dtype=float), np.array(b, dtype=float)
            d = b - a
            if plane == "xy":
                n = np.array([-d[1], d[0], 0.0])
                off = [0, 0, thick]
            elif plane == "xz":
                n = np.array([-d[2], 0.0, d[0]])
                off = [0, thick, 0]
            else:
                n = np.array([0.0, -d[2], d[1]])
                off = [thick, 0, 0]
            n = n / np.linalg.norm(n) * width / 2
            return prism([a + n, b + n, b - n, a - n], off, color)

        def block(center, dims, color):
            x, y, z = center
            dx, dy, dz = dims
            return prism(
                [
                    [x - dx / 2, y - dy / 2, z - dz / 2],
                    [x + dx / 2, y - dy / 2, z - dz / 2],
                    [x + dx / 2, y + dy / 2, z - dz / 2],
                    [x - dx / 2, y + dy / 2, z - dz / 2],
                ],
                [0, 0, dz],
                color,
            )

        def joint(x, y, z):
            return block((x, y, z), (9, 9, 9), PALETTE["pin"])

        def spring(a, b, radius=6, turns=10, color=PALETTE["ink"]):
            a, b = np.array(a, dtype=float), np.array(b, dtype=float)
            d = b - a
            u = d / np.linalg.norm(d)
            v = np.cross(u, [0, 0, 1.0])
            v /= np.linalg.norm(v)
            pts = []
            for t in np.linspace(0, 1, turns * 16 + 1):
                amp = min(1, t * 20, (1 - t) * 20) * radius
                pt = (
                    a
                    + t * d
                    + amp
                    * (
                        v * math.cos(t * turns * TAU)
                        + np.array([0, 0, 1.0]) * math.sin(t * turns * TAU)
                    )
                )
                pts.append(p(*pt))
            return (
                VMobject(stroke_color=color, stroke_width=2.2)
                .set_points_as_corners(pts)
                .set_flat_stroke(False)
                .apply_depth_test()
            )

        def body():
            lo, up, k, lower_width, upper_width, lower_locked, upper_locked = state(
                clock.get_value()
            )
            result = Group()
            lower_pivot, upper_pivot = lo + 50, up - 50
            middle_z = (lower_pivot + upper_pivot) / 2
            stage_height = middle_z - lower_pivot

            b = math.sqrt(375**2 - stage_height**2)
            # Central XZ scissor: X is the wall normal, Y=0 is the module centre.
            # The two crossing bars use separate Y layers to avoid coplanar overlap.
            for za, zb in [
                (lower_pivot, middle_z),
                (middle_z, upper_pivot),
            ]:
                for side in [-1, 1]:
                    result.add(
                        beam(
                            (-side * b / 2, side * 8, za),
                            (side * b / 2, side * 8, zb),
                            30,
                            12,
                            PALETTE["scissor"],
                            "xz",
                        )
                    )

                # Centre pivot of each individual scissor stage
                center_z = (za + zb) / 2

                result.add(
                    block(
                        (0, 6, center_z),
                        (10, 36, 10),
                        PALETTE["pin"],
                    )
                )
                result.add(joint(0, 24, center_z))
            # Only scissor end guides remain; the diamond's central slides are removed.
            # Guide beams sit behind the scissor, linked by transverse pivot shafts.
            for zrail in [lower_pivot, upper_pivot]:
                result.add(block((0, -34, zrail), (330, 20, 12), PALETTE["metal"]))
                result.add(
                    Line(
                        p(-160, -45, zrail + 7),
                        p(160, -45, zrail + 7),
                        stroke_color=PALETTE["muted"],
                        stroke_width=2,
                    )
                )
                for side in [-1, 1]:
                    result.add(
                        beam(
                            (side * b / 2, -34, zrail),
                            (side * b / 2, 24, zrail),
                            6,
                            6,
                            PALETTE["pin"],
                        )
                    )
                    result.add(joint(side * b / 2, 24, zrail + 3))

            for side in [-1, 1]:
                x_joint = side * b / 2

                # Shaft through both scissor-bar layers
                result.add(
                    block(
                        (x_joint, 6, middle_z),
                        (13, 36, 13),
                        PALETTE["pin"],
                    )
                )

                # Rear shaft cap
                result.add(
                    block(
                        (x_joint, -14, middle_z),
                        (20, 6, 20),
                        PALETTE["metal"],
                    )
                )

                # Front shaft cap
                result.add(
                    block(
                        (x_joint, 26, middle_z),
                        (20, 6, 20),
                        PALETTE["metal"],
                    )
                )

            for is_upper, z in [(False, lo), (True, up)]:
                width = upper_width if is_upper else lower_width
                q = math.sqrt(460**2 - (width - 120) ** 2) / 2
                x = (width - 120) / 2
                color = PALETTE["primary"]
                # Short fixed stems connect the diamond side vertices to its support beam.
                # No guide rail, slider or fixed spring anchor inside the diamond.
                for side in [-1, 1]:
                    mount_z = z - 50 if is_upper else z + 50
                    result.add(
                        beam(
                            (side * x, 0, z),
                            (side * x, -60, z),
                            16,
                            10,
                            PALETTE["metal"],
                        )
                    )
                    result.add(
                        block(
                            (side * x, -60, (z + mount_z) / 2),
                            (16, 16, 50),
                            PALETTE["metal"],
                        )
                    )
                    result.add(
                        beam(
                            (side * x, -60, mount_z),
                            (side * x, -34, mount_z),
                            16,
                            10,
                            PALETTE["metal"],
                        )
                    )
                vertices = [(-x, 0, z), (0, q, z), (x, 0, z), (0, -q, z)]
                for j in range(4):
                    result.add(beam(vertices[j], vertices[(j + 1) % 4], 26, 14, color))
                # One continuous tension spring joins the two opposite Y vertices.
                # Its endpoints follow the full diamond diagonal, with no centre anchor.
                result.add(spring((0, -q, z + 16), (0, q, z + 16), 9, 22))
                locked = upper_locked if is_upper else lower_locked
                pad_color = PALETTE["ink"] if locked else PALETTE["released"]
                for side in [-1, 1]:
                    foot = side * width / 2
                    node = side * x
                    # One rigid transverse foot beam; pads attach directly to its ends.
                    # Its outer face meets the pad's inner face (no preload carriage).
                    result.add(
                        beam((node, 0, z), (foot - side * 16, 0, z), 22, 14, color)
                    )
                    result.add(block((foot - side * 16, 0, z), (20, 500, 22), color))
                    for y in [-230, 230]:
                        result.add(
                            block((foot - side * 3, y, z), (6, 40, 40), pad_color)
                        )
                for xx, yy, zz in vertices:
                    result.add(joint(xx, yy, zz + 15))
            return result.apply_depth_test()

        diagram = always_redraw(body)
        self.model_geometry = diagram
        self.add(diagram)
        # Draw translucent surfaces last, with real per-pixel depth testing.
        self.add(walls)

        def status():
            _, _, k, _, _, _, _ = state(clock.get_value())
            angle = clock.get_value() % 360
            phase = "Camera rises" if self.camera_reframing else f"{k + 1}/5  " + PHASES[k]
            return VGroup(
                label(phase, 20).move_to([-4.8, -3.15, 0]),
                label(
                    ("Paused" if self.paused else "Looping") + f"  {angle:03.0f}°",
                    18,
                    PALETTE["primary"],
                ).move_to([4.8, -3.15, 0]),
            )

        if not self.presentation_mode:
            self.add(always_redraw(status))
            self.add(
                label(
                    "Arrows: orbit | W: walls | Camera rises after each cycle",
                    16,
                    PALETTE["muted"],
                ).to_edge(DOWN)
            )
        if self.window is None:
            if self.preview_orbit:
                self.frame.add_updater(
                    lambda frame, dt: frame.increment_theta(TAU * dt / PLAYBACK_CYCLE_SECONDS)
                )
                self.wait(PLAYBACK_CYCLE_SECONDS * self.render_cycles)
                self.frame.clear_updaters()
            else:
                self.wait(PLAYBACK_CYCLE_SECONDS * self.render_cycles)
        # With a live window, Scene.run enters interact(); updaters run indefinitely.

    def on_mouse_drag(self, point, d_point, buttons, modifiers):
        self.mouse_drag_point.move_to(point)
        delta = self.frame.to_fixed_frame_point(d_point, relative=True)
        if buttons & 1:
            self.frame.increment_theta(-delta[0] * 0.6)
            self.frame.set_phi(
                np.clip(self.frame.get_phi() + delta[1] * 0.6, 5 * DEG, 175 * DEG)
            )
        elif buttons & (2 | 4):
            self.frame.shift(-d_point)

    def on_key_press(self, symbol, modifiers):
        from pyglet.window import key

        if symbol == key.SPACE:
            self.paused = not self.paused
        elif symbol == key.LEFT:
            self.frame.increment_theta(-10 * DEG)
        elif symbol == key.RIGHT:
            self.frame.increment_theta(10 * DEG)
        elif symbol in (key.UP, key.DOWN):
            sign = 1 if symbol == key.UP else -1
            self.frame.set_phi(
                np.clip(self.frame.get_phi() + sign * 5 * DEG, 5 * DEG, 175 * DEG)
            )
        elif symbol == key.R:
            self.frame.reorient(-25, 68).move_to(
                ORIGIN + 0.007 * self.camera_follow_height * np.array([0, 0, 1])
            ).set_height(8)
        elif symbol == key.W:
            self.walls_visible = not self.walls_visible
            self.wall_guides.update(0)
        else:
            super().on_key_press(symbol, modifiers)


class OrbitPreview(InteractiveCycle):
    preview_orbit = True


class PPTCycle(InteractiveCycle):
    """Clean single-cycle loop with an end-of-cycle camera rise for PowerPoint, without controls or captions."""

    presentation_mode = True


class PPTOrbit(PPTCycle):
    """Clean full orbit, one complete mechanical cycle."""

    preview_orbit = True


class PPTTwoCycles(PPTCycle):
    """Two complete cycles with camera rises, without controls or captions."""

    render_cycles = 2
