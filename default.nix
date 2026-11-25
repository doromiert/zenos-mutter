# Optional, neutral-by-default adjustment on the source version exercised here.
{ mutter }:
if mutter.version != "50.4" || (mutter.zenosSdrHdrCorrection or false) then mutter else
mutter.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ ./patches/sdr-hdr-correction.patch ./patches/paint-target-introspection.patch ];
  passthru = (old.passthru or { }) // { zenosSdrHdrCorrection = true; };
})
