# loosely based on nix-gaming
{
  makeDesktopItem,
  symlinkJoin,
  writeShellScriptBin,
  lib,
  pkgs,
  config,
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
  winePackage ? pkgs.wineWowPackages.full,
  icon ? "",
  comment ? "",
  winetricksVerbs ? [],
  extraGamescopeFlags ? "",
  extraLib ? [],
  commandPrefix ? "",
  gamePrefix ? "",
  commandPostfix ? ""
}:

let
  umu = pkgs.umu-launcher;
  scope = "systemd-run --user --scope --property TimeoutStopSec=${builtins.toString stopTimeout} --unit=\"${shortname}\"";
  exeCommand = if useUmu then "umu-run" else "wine";
  gameDir = if useGlobalPaths then "" else "${baseDir}/game/";
  baseScript = gameExecLine: ''
    export WINEPREFIX="${baseDir}/prefix"
    export WINEESYNC=1
    export DXVK_HDR=1

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
          winePackage
          winetricks
        ])
      )
    }:$PATH

    export STEAM_LIBS_PATHS="${
      lib.makeLibraryPath extraLib
    }"

    if ${lib.boolToString useUmu} && [ -n "$STEAM_LIBS_PATHS" ]; then
      echo "** Lib injection: Version check"

      export UMU_GITHUB="Open-Wine-Components/umu-proton"
      export UMU_VERSION="$(curl -I https://github.com/$UMU_GITHUB/releases/latest/download/source.tar.gz | grep "location:" | cut -d'/' -f8)"
      if [ ! -d "$HOME/.local/share/Steam/compatibilitytools.d/$UMU_VERSION" ]; then
        echo "** Lib injection: UMU out of date, updating..."
        # Update UMU-Latest if necessary by executing umu without game
        umu-run whoami
      else
        echo "** Lib injection: UMU is up to date!"
      fi

      # Set directories/libraries to inject
      export PROTONPATH="${baseDir}/proton"
      export BASEPROTONPATH="$HOME/.local/share/Steam/compatibilitytools.d/$UMU_VERSION"
      export STEAM_LIBS_INJECT_PATH="$PROTONPATH/files/lib64"

      echo "** Lib injection: Overlaying Proton..."


      # Copy latest proton to it's own directory
      # Set permissions; some paths are set 555 preventing removal
      chmod -R 777 $PROTONPATH
      rm -rf $PROTONPATH
      mkdir -p $PROTONPATH
      cp --reflink=auto -r "$BASEPROTONPATH/." "$PROTONPATH"

      echo "** Lib injection: Injecting extraLib into Proton..."

      # Hack in extra libraries into Proton compatibility tool
      chmod a+w $STEAM_LIBS_INJECT_PATH
      (IFS=:
        for PATH in $STEAM_LIBS_PATHS; do
          echo "** DEBUG: Copy $PATH --> $STEAM_LIBS_INJECT_PATH"
          ${pkgs.coreutils}/bin/cp --reflink=auto -r "$PATH/." "$STEAM_LIBS_INJECT_PATH"
        done
      )
      chmod a-w $STEAM_LIBS_INJECT_PATH

      echo "** Lib injection: Complete!"
    fi

    USER="$(whoami)"

    if [ ! -d "$WINEPREFIX" ]; then
      echo "** Prefix: Creating new prefix and installing dependencies"
      ${if useUmu then "umu-run" else ""} winetricks ${lib.strings.concatStringsSep " " winetricksVerbs}
      if ${lib.boolToString (! useUmu)}; then
        ${pkgs.dxvk}/bin/setup_dxvk.sh install
      fi
    else
      echo "** Prefix: Prefix exists, skipping creation"
    fi

    if [ ! -f "${baseDir}/is_installed" ]; then
      echo "** Game: Not installed, running installer"
      touch "${baseDir}/is_installed"
      TEMPDIR=$(mktemp -d)
      curl -L ${installerUrl} -o "$TEMPDIR/installer.exe"
      ${scope} ${pkgs.gamemode}/bin/gamemoderun ${exeCommand} "$TEMPDIR/installer.exe" "$@"
    else
      echo "** Game: Already installed, launch!"
      ${gameExecLine}
    fi
  '';
  script = writeShellScriptBin shortname (baseScript ''${scope} ${commandPrefix} ${pkgs.gamemode}/bin/gamemoderun ${pkgs.gamescope}/bin/gamescope ${config.gamescopeFlags} ${extraGamescopeFlags} -- ${gamePrefix} ${exeCommand} "${gameDir}${mainBinary}" ${commandPostfix}'');
  launcherScript = writeShellScriptBin (shortname + "-launcher") (baseScript ''${scope} ${commandPrefix} ${pkgs.gamemode}/bin/gamemoderun ${exeCommand} "${gameDir}${launcherBinary}" ${commandPostfix}'');

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
