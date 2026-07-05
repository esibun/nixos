{pkgs, ...}:

{
  imports = [
    ../common.nix

    ../profiles/desktop.nix
    ../profiles/gaming.nix
    ../profiles/gaming-beatoraja.nix
  ];

  gamescopeFlags = "-w 2560 -h 1600 -r 144 -F fsr -f";

  home = {
    homeDirectory = "/home/esi";
    packages = with pkgs; [
      brightnessctl
    ];
    stateVersion = "23.11";
    username = "esi";
  };

  wayland.windowManager.hyprland = let
    # TODO: this isn't DRY; this really should be in a common file
    keybind = x: {
      _args = [
        x.key
      ]
      # func is a string e.g. "dsp.focus"
      #  translates to hl.bind("key", (dsp.focus())
      ++ (lib.optional (builtins.isString x.func) (
        lib.mkLuaInline ("hl." + x.func)
      ))
      # func = list, first elem is call, second elem is args e.g. "dsp.window.move(workspace = 1)"
      #  translates to hl.bind("key", dsp.window.move(workspace = 1))
      #  NOTE: use double single quotes for escaping, i.e. ''arg = "string"''
      #  TODO: write something to properly interpret sets into arguments (lib.generators.toLua doesn't
      #   for this since it doesn't insert commas)
      ++ (lib.optional (builtins.isList x.func) (
        lib.mkLuaInline ("hl." + x.func)
      ))
      # pass flags as-is if defined
      ++ (lib.optional (builtins.hasAttr "flags" x) x.flags);
    };
  in {
    settings = {
      config = {
        input = {
          sensitivity = 0.75;
          accel_profile = "flat";
        };
      };
      monitor = [
        {
          output = "eDP-2";
          mode = "preferred";
          position = "auto";
          scale = 1;
          vrr = 0;
        }
      ];
      bind = [
        (keybind { key = "XF86MonBrightnessUp"; func = ''dsp.exec_cmd("${pkgs.brightnessctl}/bin/brightnessctl s 10%+")''; })
        (keybind { key = "XF86MonBrightnessDown"; func = ''dsp.exec_cmd("${pkgs.brightnessctl}/bin/brightnessctl s 10%-")''; })
      ];
    };
  };
}
