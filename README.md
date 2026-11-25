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
