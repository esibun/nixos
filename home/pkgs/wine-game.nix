# loosely based on nix-gaming
{
  makeDesktopItem,
  symlinkJoin,
  writeShellScriptBin,
  lib,
  pkgs,
  umu, #TODO: can we inherit this from flake inputs?

  title,
  baseDir,
  shortname,
  installerUrl,
  stopTimeout ? 2,
  launcherBinary ? "",
  mainBinary,
  icon ? "",
  comment ? "",
  winetricksVerbs ? [],
  gamescopeFlags ? ""
}:

let
  scope = "systemd-run --user --scope --property TimeoutStopSec=${builtins.toString stopTimeout} --unit=\"${shortname}\"";
  baseScript = gameExecLine: ''
    export WINEPREFIX="${baseDir}/prefix"
    export GAMEDIR="${baseDir}/game"
    export WINEESYNC=1

    export GAMEID="${shortname}"
    export STORE="none"

    PATH=${
      lib.makeBinPath [umu]
    }:$PATH
    USER="$(whoami)"

    if [ ! -d "$WINEPREFIX" ]; then
      umu-run winetricks ${lib.strings.concatStringsSep " " winetricksVerbs}
    fi

    if [ ! -f "${baseDir}/is_installed" ]; then
      touch "${baseDir}/is_installed"
      TEMPDIR=$(mktemp -d)
      curl ${installerUrl} -o "$TEMPDIR/installer.exe"
      ${scope} ${pkgs.gamemode}/bin/gamemoderun umu-run "$TEMPDIR/installer.exe" "$@"
    else
      ${gameExecLine}
    fi
  '';
  script = writeShellScriptBin shortname (baseScript ''${scope} ${pkgs.gamemode}/bin/gamemoderun ${pkgs.gamescope}/bin/gamescope ${gamescopeFlags} -- umu-run "$GAMEDIR/${mainBinary}"'');
  launcherScript = writeShellScriptBin (shortname + "-launcher") (baseScript ''${scope} ${pkgs.gamemode}/bin/gamemoderun ${pkgs.gamescope}/bin/gamescope ${gamescopeFlags} -- umu-run "$GAMEDIR/${launcherBinary}"'');

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
