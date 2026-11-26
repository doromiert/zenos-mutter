# ZenOS Mutter color adjustments

Optional per-output SDR corrections while the output remains HDR. Based on
GNOME Mutter 50.4. GNOME's original files retain their licenses and attribution:
Mutter is GPL-2.0-or-later, Clutter is LGPL-2.0-or-later (see COPYING files).

Apply `patches/sdr-hdr-correction.patch` after the 50.4 HDR metadata follow-up
35eda8a55e811aa0086fd2b5a33be9e5da9a0b72. It is independent of the touch-focus
fix used by ZenOS. The companion `sdr-hdr-correction-tests.patch` adds native CPU/GPU regression
tests in `color-state-transform`.

The `org.gnome.mutter sdr-hdr-corrections` setting is an array of
(connector, vendor, product, serial, curve exponent, saturation) tuples.
Default `[]` leaves all outputs unchanged. The curve and saturation defaults
are both 1.0. Matching uses all four output identity fields, and the profile
is applied only in HDR output mode. Changes update live, without restarting
apps or changing the output HDR mode.

Correction happens in linear source RGB before luminance/gamut conversion.
Only parameterized sRGB SDR sources without mastering headroom are affected.
Black and reference white stay fixed. PQ sources, HDR blending buffers,
ICC-tagged and wide-gamut sources bypass correction. Native HDR scanout is
not disqualified merely because the output has an SDR correction profile.

The `sdr-hdr-grading` setting extends this with Color Compare appearance profiles.
Its type is `a(ssssad)`: connector, vendor, product, serial and ten doubles in
this order: exposure (stops), contrast, gamma, saturation, shadows, red gain,
green gain, blue gain, SDR white (nits), hue (degrees). A matching profile replaces
the legacy curve/saturation pair. Inputs are validated against the preview's
slider ranges. An empty array leaves legacy behavior unchanged.

Grading follows the preview: encoded-sRGB contrast/shadow/gamma adjustment,
linear RGB exposure/gains and luminance-preserving saturation/hue. Negative
working-space channels survive until gamut conversion, permitting HDR output
beyond sRGB. SDR white is independently scaled without changing native HDR.
Profiles propagate into blending states; mastering headroom prevents repeated
grading. Native tests cover multiple profiles and neutral transitions,
independent reference values, CPU/GPU agreement and unchanged HDR pixels.

This is a user-controlled appearance adjustment, not a measured calibration
or a diagnosis of a monitor/firmware defect. It cannot selectively correct SDR
UI already merged into a single HDR app surface: applications should use SDR
parent surfaces and color-tagged HDR media subsurfaces for that case.

## Testing

`tests.nix` builds the companion tests against the patched Mutter package.
Alternatively build Mutter with `-Dtests=enabled -Dclutter_tests=true`, then run the
`color-state-transform` suite with Mutter's normal headless test environment.
New cases exercise multiple profile values, GPU versus CPU transforms through
HDR blending, and native HDR bypass. Hardware display appearance and HDR media
presentation still need end-to-end acceptance on the target monitor.

Verified locally with Mutter 50.4, GLib 2.88.3, and native AMD render nodes:
all seven color-state-transform cases pass, including actual HDR buffer/output
pixel equality with correction enabled and disabled. Personal display settings
and the interactive comparison GUI are intentionally outside this source repo.

## Offscreen effects and HDR

`paint-target-introspection.patch` exposes the existing paint-context target
color state to GJS with borrowed ownership. It changes API metadata only.
An SDR window actor can contain HDR subsurfaces: effects must retain the current
paint target encoding, not first flatten children into the actor's SDR space.
Rounded Window Corners Native uses this getter to avoid window-state-dependent
tone mapping, and chooses FP16 intermediates for HDR/linear paint targets.

The native rounded-corners fixture on GNOME Shell/Mutter50.4 reproduces the
old darkening (PQ gray148 becomes137 only while rounded); the corrected path
keeps gray bands identical when rounded, maximized and restored. This does not
establish appearance on every physical monitor.

## Six-color SDR mixer

`org.gnome.mutter sdr-hdr-color-mixer` is `a(ssssad)`, using the same exact
connector/vendor/product/serial identity and eighteen values. Band order is red,
yellow, green, cyan, blue, magenta; each band supplies hue (-30..30 degrees),
saturation (0..2, neutral1), brightness (-1..1 exposure stops, neutral0). Default
is empty, and a neutral profile has no effect. Finite values and exact length are
validated before applying. The existing ten-value grading API stays unchanged.

Weights use the source's encoded-sRGB hue with smooth transitions to neighboring
bands. Near-neutral saturation fades the adjustment out completely; red-only
adjustments preserve pure yellow and a neutral ramp. Hue/chroma use linear
Rec709-luminance-preserving UV rotation/scaling, with selective brightness in
stops. The mixer follows global grading, while its band selection uses the
original source color, so global hue/gain changes do not move selection bands.
Extended working RGB survives until destination conversion. This remains bounded
to parameterized sRGB SDR sources in HDR mode; native HDR/ICC/wide-gamut source
limitations of the earlier grading patch remain. There is no extra render pass.

All eleven native color-transform tests pass in the isolated Mesa26.1.8
surfaceless environment on Mutter50.4/GLib2.88.3. New cases check all six bands,
neutral transitions, CPU/GPU agreement, gray protection, red-versus-yellow
separation and actual HDR pixel bypass. This is technical verification, not a
physical monitor calibration or a new AMD-hardware test.

## Desktop brightness and grading

The grading white is relative to the output transfer function's nominal reference
(PQ203nits), before GNOME's reference-luminance factor. Capturing the already
brightness-adjusted white in the grading denominator cancelled the slider's
subsequent luminance mapping. Preserve this nominal baseline through HDR blend
states (whose own nominal white is80nits). At nominal brightness the accepted
profile is unchanged; lowering the desktop reference now scales graded SDR.
Native HDR still bypasses custom grading and retains ordinary Mutter behavior.
The regression test decodes PQ and checks the accepted +1EV/204.44nit profile at
reference factors1.0,0.5,0.2,1.0, alongside CPU/GPU pixels and dimmed-HDR bypass.
All13 native render tests pass in Mesa26.1.8 surfaceless/GLib2.88.3 on Mutter50.4.
The same named-PQ regression against the prior implementation fails at half
brightness:408.884nits versus expected204.44nits. Production build also passes.
