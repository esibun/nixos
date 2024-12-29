# loosely based on nix-gaming
{
  makeDesktopItem,
  symlinkJoin,
  writeShellScriptBin,
  lib,
  pkgs,
  inputs,
  system,

  title,
  baseDir,
  shortname,
  installerUrl,
  useUmu ? true,
  stopTimeout ? 2,
  launcherBinary ? "",
  mainBinary,
  icon ? "",
  comment ? "",
  winetricksVerbs ? [],
  gamescopeFlags ? "",
  extraLib ? [],
  commandPrefix ? "",
  commandPostfix ? ""
}:

let
  umu = inputs.umu.packages.${system}.umu;
  scope = "systemd-run --user --scope --property TimeoutStopSec=${builtins.toString stopTimeout} --unit=\"${shortname}\"";
  exeCommand = if useUmu then "umu-run" else "wine";
  baseScript = gameExecLine: ''
    export WINEPREFIX="${baseDir}/prefix"
    export GAMEDIR="${baseDir}/game"
    export WINEESYNC=1

    export GAMEID="${shortname}"
    export STORE="none"
    # TODO: UMU - this gets overridden by pressure-vessel atm
    export LD_LIBRARY_PATH=${
      lib.makeLibraryPath extraLib
    }:$LD_LIBRARY_PATH

    PATH=${
      lib.makeBinPath (
        lib.optional useUmu umu ++
        lib.optionals (! useUmu) (with pkgs; [
          wineWowPackages.full
          winetricks
        ])
      )
    }:$PATH
    USER="$(whoami)"

    if [ ! -d "$WINEPREFIX" ]; then
      ${if useUmu then "umu-run" else ""} winetricks ${lib.strings.concatStringsSep " " winetricksVerbs}
      if [ ${builtins.toString (! useUmu)} ]; then
        ${pkgs.dxvk}/bin/setup_dxvk.sh
      fi
    fi

    if [ ! -f "${baseDir}/is_installed" ]; then
      touch "${baseDir}/is_installed"
      TEMPDIR=$(mktemp -d)
      curl ${installerUrl} -o "$TEMPDIR/installer.exe"
      ${scope} ${pkgs.gamemode}/bin/gamemoderun ${exeCommand} "$TEMPDIR/installer.exe" "$@"
    else
      ${gameExecLine}
    fi
  '';
  script = writeShellScriptBin shortname (baseScript ''${scope} ${commandPrefix} ${pkgs.gamemode}/bin/gamemoderun ${pkgs.gamescope}/bin/gamescope ${gamescopeFlags} -- ${exeCommand} "$GAMEDIR/${mainBinary}" ${commandPostfix}'');
  launcherScript = writeShellScriptBin (shortname + "-launcher") (baseScript ''${scope} ${commandPrefix} ${pkgs.gamemode}/bin/gamemoderun ${pkgs.gamescope}/bin/gamescope ${gamescopeFlags} -- ${exeCommand} "$GAMEDIR/${launcherBinary}" ${commandPostfix}'');

  desktopItem = makeDesktopItem {
    name = shortname;
    exec = "${script}/bin/${shortname} %U";
    icon = icon;
    comment = comment;
    desktopName = title;
    categories = ["Game"];
  };
  desktopItemLauncher = makeDesktopItem {
    name = shortname + "-launcher";
    exec = "${launcherScript}/bin/${shortname}-launcher %U";
    icon = icon;
    comment = comment;
    desktopName = title + " (Launcher)";
    categories = ["Game"];
  };
in
symlinkJoin {
  name = shortname;
  paths = [
    desktopItem
    script
  ] ++ (lib.optionals (launcherBinary != "") [
    launcherScript
    desktopItemLauncher
  ]);
}
