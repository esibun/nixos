# loosely based on nix-gaming
{
  makeDesktopItem,
  symlinkJoin,
  writeShellScriptBin,
  lib,
  pkgs,
  system,

  title,
  baseDir,
  shortname,
  installerUrl,
  useUmu ? true,
  stopTimeout ? 2,
  useGlobalPaths ? false,
  launcherBinary ? "",
  mainBinary,
  icon ? "",
  comment ? "",
  winetricksVerbs ? [],
  gamescopeFlags ? "",
  extraLib ? [],
  commandPrefix ? "",
  gamePrefix ? "",
  commandPostfix ? ""
}:

let
  umu = pkgs.unstable.umu-launcher;
  scope = "systemd-run --user --scope --property TimeoutStopSec=${builtins.toString stopTimeout} --unit=\"${shortname}\"";
  exeCommand = if useUmu then "umu-run" else "wine";
  gameDir = if useGlobalPaths then "" else "${baseDir}/game/";
  baseScript = gameExecLine: ''
    export WINEPREFIX="${baseDir}/prefix"
    export WINEESYNC=1

    export GAMEID="${shortname}"
    export STORE="none"

    PATH=${
      lib.makeBinPath (
        lib.optionals useUmu (with pkgs; [
          umu
          fuse
          fuse-overlayfs
        ])++
        lib.optionals (! useUmu) (with pkgs; [
          wineWowPackages.full
          winetricks
        ])
      )
    }:$PATH

    export STEAM_LIBS_PATHS="${
      lib.makeLibraryPath extraLib
    }"

    # Check if prefix exists before we run UMU; if it doesn't we need to run winetricks.
    # umu-run will create the prefix the first time it's run regardless of the command.
    if [ ! -d "$WINEPREFIX" ]; then
      PREFIX_EXISTS=false
    else
      PREFIX_EXISTS=true
    fi

    if ${lib.boolToString useUmu} && [ -n "$STEAM_LIBS_PATHS" ]; then
      echo "** Lib injection: Updating UMU..."
      # Update UMU-Latest if necessary by executing umu without game
      umu-run whoami

      # Set directories/libraries to inject
      export PROTONPATH="$(readlink -f $HOME/.local/share/Steam/compatibilitytools.d/UMU-Latest)-${shortname}"
      export BASEPROTONPATH="$(readlink -f $HOME/.local/share/Steam/compatibilitytools.d/UMU-Latest)"
      export STEAM_LIBS_INJECT_PATH="$PROTONPATH/files/lib64"

      echo "** Lib injection: Cleaning up any old mounts..."

      # Unmount any previous overlayfs mounts
      fusermount3 -u $STEAM_LIBS_INJECT_PATH || true
      rm -rf "$(dirname $PROTONPATH)/*-${shortname}" || true

      echo "** Lib injection: Overlaying Proton..."

      # Copy latest proton to it's own directory
      #
      # Ideally we'd be using some form of no-copy mount here, but overlayfs gets really upset when you try to
      #  do a nested mount in userspace.  Tell CP to reflink if possible, but fallback to copy if not.
      mkdir -p $PROTONPATH
      cp --reflink=auto -r "$BASEPROTONPATH/." "$PROTONPATH"

      echo "** Lib injection: Injecting extraLib into Proton..."

      # Hack in extra libraries into Proton compatibility tool
      # NOTE: lowerdir file priority is left-to-right
      # NOTE: Maximum overlayfs depth is 2; if we want to do anything more complicated than this, we will need to
      #  find another solution
      fuse-overlayfs -o lowerdir=$STEAM_LIBS_PATHS:$STEAM_LIBS_INJECT_PATH $STEAM_LIBS_INJECT_PATH

      echo "** Lib injection: Complete!"
    fi

    USER="$(whoami)"

    if [ ! $PREFIXEXISTS ]; then
      ${if useUmu then "umu-run" else ""} winetricks ${lib.strings.concatStringsSep " " winetricksVerbs}
      if ${lib.boolToString (! useUmu)}; then
        ${pkgs.dxvk}/bin/setup_dxvk.sh install
      fi
    fi

    if [ ! -f "${baseDir}/is_installed" ]; then
      touch "${baseDir}/is_installed"
      TEMPDIR=$(mktemp -d)
      curl -L ${installerUrl} -o "$TEMPDIR/installer.exe"
      ${scope} ${pkgs.gamemode}/bin/gamemoderun ${exeCommand} "$TEMPDIR/installer.exe" "$@"
    else
      ${gameExecLine}
    fi
  '';
  script = writeShellScriptBin shortname (baseScript ''${scope} ${commandPrefix} ${pkgs.gamemode}/bin/gamemoderun ${pkgs.gamescope}/bin/gamescope ${gamescopeFlags} -- ${gamePrefix} ${exeCommand} "${gameDir}${mainBinary}" ${commandPostfix}'');
  launcherScript = writeShellScriptBin (shortname + "-launcher") (baseScript ''${scope} ${commandPrefix} ${pkgs.gamemode}/bin/gamemoderun ${pkgs.gamescope}/bin/gamescope ${gamescopeFlags} -- ${exeCommand} "${gameDir}${launcherBinary}" ${commandPostfix}'');

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
