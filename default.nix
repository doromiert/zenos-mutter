# Optional, neutral-by-default adjustment on the source version exercised here.
{ mutter }:
if mutter.version != "50.4" || (mutter.zenosSdrHdrCorrection or false) then mutter else
mutter.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ ./patches/sdr-hdr-correction.patch ./patches/sdr-hdr-grading.patch ./patches/sdr-hdr-color-mixer.patch ./patches/sdr-hdr-brightness.patch ./patches/sdr-hdr-curve.patch ./patches/stage-view-backbuffer-reuse.patch ./patches/paint-target-introspection.patch ];
  passthru = (old.passthru or { }) // { zenosSdrHdrCorrection = true; };
})
