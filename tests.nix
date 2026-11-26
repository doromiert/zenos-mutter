{ pkgs, mutter }:
let
  python = pkgs.python3.withPackages (ps: [ ps.dbus-python ps.python-dbusmock ps.pygobject3 ]);
in mutter.overrideAttrs (old: {
  outputs = [ "out" ];
  separateDebugInfo = false;
  dontWrapGApps = true;
  patches = (old.patches or [ ]) ++ [ ./patches/sdr-hdr-correction-tests.patch ./patches/sdr-hdr-grading-tests.patch ./patches/sdr-hdr-color-mixer-tests.patch ./patches/sdr-hdr-brightness-tests.patch ./patches/sdr-hdr-curve-tests.patch ];
  mesonFlags = builtins.filter (x: x != "-Dtests=disabled" && x != "-Ddocs=true") old.mesonFlags
    ++ [ "-Dtests=enabled" "-Dmutter_tests=false" "-Dcogl_tests=false" "-Ddocs=false" ];
  nativeBuildInputs = old.nativeBuildInputs ++ [ python pkgs.dbus ];
  buildInputs = old.buildInputs ++ [ pkgs.gtk3 pkgs.umockdev ];
  postPatch = (old.postPatch or "") + ''
    substituteInPlace src/tests/meta-dbus-runner.py \
      --replace-fail '#!/usr/bin/env python3' '#!${python}/bin/python3'
  '';
  buildPhase = ''ninja -j$NIX_BUILD_CORES src/tests/clutter/conform/color-state-transform data/gschemas.compiled'';
  doCheck = true;
  checkPhase = ''
    export HOME="$TMPDIR/home" XDG_RUNTIME_DIR="$TMPDIR/runtime"
    mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
    chmod 700 "$XDG_RUNTIME_DIR"
    export XDG_DATA_DIRS="${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gnome-settings-daemon}/share/gsettings-schemas/${pkgs.gnome-settings-daemon.name}"
    export META_DBUS_RUNNER_DISABLE_LOGIND_PASSTHROUGH=1 META_DBUS_RUNNER_DISABLE_UMOCKDEV=1
    export __EGL_VENDOR_LIBRARY_FILENAMES=${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json
    export LIBGL_DRIVERS_PATH=${pkgs.mesa}/lib/dri LIBGL_ALWAYS_SOFTWARE=1
    $CC ../src/tests/sdr-curve-unit.c -lm -o sdr-curve-unit
    ./sdr-curve-unit
    meson test --setup mutter:default color-state-transform --print-errorlogs
  '';
  installPhase = ''mkdir -p "$out"; cp meson-logs/testlog* "$out/"'';
})
