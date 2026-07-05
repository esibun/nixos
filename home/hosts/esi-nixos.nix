{pkgs, lib, ...}:

{
  imports = [
    ../common.nix

    ../profiles/desktop.nix
    ../profiles/gaming.nix
    ../profiles/gaming-beatoraja.nix
    ../profiles/vfio.nix
  ];

  gamescopeFlags = "-w 3840 -h 2160 -r 480 -F fsr --hdr-enabled -f";

  home = {
    homeDirectory = "/home/esi";
    packages = with pkgs; [
      fcast-receiver
      libimobiledevice
      qbittorrent
    ];
    stateVersion = "23.11";
    username = "esi";
  };

  wayland.windowManager.hyprland = {
    extraConfig = lib.mkAfter ''
      hl.on("config.reloaded", function()
        hl.dsp.exec_cmd("${pkgs.uwsm}/bin/uwsm app -- ${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnect-indicator")
      end)
    '';
    settings = {
      config = {
        input = {
          sensitivity = -0.333;
          accel_profile = "flat";
        };
      };
      monitor = [
        {
          output = "DP-1";
          mode = "3840x2160@240";
          position = "0x0";
          scale = 1;
          vrr = 1;
        }
        {
          output = "DP-2";
          mode = "3840x2160@144";
          position = "3840x-200";
          scale = 1.5;
          vrr = 1;
        }
        {
          output = "HDMI-A-1";
          mode = "1920x1080@60";
          position = "0x0";
          scale = 1;
        }
      ];
      workspace_rule = [
        {
          workspace = 1;
          monitor = "DP-1";
        }
        {
          workspace = 2;
          monitor = "DP-2";
        }
        {
          workspace = 3;
          monitor = "DP-2";
        }
        {
          workspace = 4;
          monitor = "DP-2";
        }
        {
          workspace = 5;
          monitor = "DP-2";
        }
      ];
    };
  };
}
