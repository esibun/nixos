# loosely based on nix-gaming
{
  makeDesktopItem,
  symlinkJoin,
  writeShellScriptBin,
  lib,
  pkgs,

  title,
  baseDir,
  shortname,
  installerUrl ? "",
  stopTimeout ? 2,
  useGlobalPaths ? false,
  launcherBinary ? "",
  mainBinary,
  icon ? "",
  comment ? "",
  gamescopeFlags ? "",
  extraLib ? [],
  commandPrefix ? "",
  gamePrefix ? "",
  commandPostfix ? ""
}:

let
  scope = "systemd-run --user --scope --property TimeoutStopSec=${builtins.toString stopTimeout} --unit=\"${shortname}\"";
  baseScript = gameExecLine: ''
    export LD_LIBRARY_PATH="${
      lib.makeLibraryPath extraLib
    }"

    USER="$(whoami)"

    if [ ${lib.boolToString (installerUrl != "")} ] && [ ! -f "${baseDir}/is_installed" ]; then
      touch "${baseDir}/is_installed"
      TEMPDIR=$(mktemp -d)
      curl ${installerUrl} -o "$TEMPDIR/"
      ${scope} ${pkgs.gamemode}/bin/gamemoderun "$TEMPDIR/*" "$@"
    else
      ${gameExecLine}
    fi
  '';
  gameDir = if useGlobalPaths then "" else "${baseDir}/";
  script = writeShellScriptBin shortname (baseScript ''${scope} ${commandPrefix} ${pkgs.gamemode}/bin/gamemoderun ${pkgs.gamescope}/bin/gamescope ${gamescopeFlags} -- ${gamePrefix} "${gameDir}${mainBinary}" ${commandPostfix}'');
  launcherScript = writeShellScriptBin (shortname + "-launcher") (baseScript ''${scope} ${commandPrefix} ${pkgs.gamemode}/bin/gamemoderun ${pkgs.gamescope}/bin/gamescope ${gamescopeFlags} -- "${gameDir}${launcherBinary}" ${commandPostfix}'');

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
