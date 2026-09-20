{ pkgs, ... }:
let
  dotnet = pkgs.dotnet-sdk_10;
in
pkgs.buildFHSEnv {
  name = "rider";
  targetPkgs =
    p: with p; [
      jetbrains.rider
      dotnet-sdk_10
      powershell
      icu
      openssl
      zlib
    ];
  profile = ''
    export DOTNET_ROOT="${dotnet}/share/dotnet"
  '';
  runScript = "${pkgs.jetbrains.rider}/bin/rider";
  meta.mainProgram = "rider";
}
