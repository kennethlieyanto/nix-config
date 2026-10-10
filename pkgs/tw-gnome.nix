{
  lib,
  stdenvNoCC,
  glib,
  src,
}:

stdenvNoCC.mkDerivation {
  pname = "gnome-shell-extension-taskwarrior";
  version = "0.1.0";

  inherit src;

  nativeBuildInputs = [ glib ];

  buildPhase = ''
    runHook preBuild
    glib-compile-schemas --strict schemas
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    dest="$out/share/gnome-shell/extensions/taskwarrior@kennethl.dev"
    mkdir -p "$dest"
    cp metadata.json extension.js prefs.js taskwarrior.js task-format.js stylesheet.css "$dest/"
    cp -r schemas "$dest/"
    runHook postInstall
  '';

  passthru.extensionUuid = "taskwarrior@kennethl.dev";

  meta = {
    description = "GNOME Shell extension for Taskwarrior";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
