{pkgs, lib, inputs, ...}:

{
  fonts.fontconfig.enable = true;

  home = {
    file = {
      ".config/nvim" = {
        source = ../files/configs/nvim;
        recursive = true;
      };

      ".config/starship.toml".source = ../files/configs/starship/starship.toml;
    };
    packages = with pkgs; [
      # Command Prompt
      starship

      # Development
      git
      lazygit
      unstable.neovim

      # Utilities
      inputs.agenix.packages.${system}.default
      any-nix-shell
      unzip
    ];
    sessionVariables = {
      EDITOR = "nvim";
    };
  };

  programs = {
    bash = {
      enable = true;
      initExtra = ''
        if [ $(tty) == "/dev/tty1" ]; then
          exec sway
        fi
        if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != ".any-nix-shell-" && -z ''${BASH_EXECUTION_STRING} ]]
        then
          shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
          exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
        fi
      '';
    };
    fish = {
      enable = true;
      interactiveShellInit = ''
        set -g fish_greeting "🐟"
      '';
      shellInit = ''
        set PATH "$HOME/.local/bin:$PATH"
        
        function get_inherited_vars
          for item in (set -ng)
            if test "$item" != "status_generation"
              echo "$item"
            end
          end
        end
        
        function fish_prompt_loading_indicator -a last_prompt
          echo -n "$last_prompt" | sed -r 's/\x1B\[[0-9;]*[JKmsu]//g' | read -zl uncolored_last_prompt
          echo -n (set_color brblack)"$uncolored_last_prompt"(set_color normal)
        end
        
        set -U async_prompt_inherit_variables (get_inherited_vars)
        set -U async_prompt_functions fish_prompt
        
        starship init fish | source
        any-nix-shell fish | source
      '';
      shellAbbrs = {
        vim = "nvim";
      };
      plugins = [
        { name = "bass"; src = pkgs.fishPlugins.bass; }
      ];
    };
    ssh = {
      enable = true;
      matchBlocks = {
        "esi-nixos".user = "esi";
        "esi-laptop".user = "esi";
        "esi-phone".user = "nix-on-droid";
        "*" = lib.hm.dag.entryAfter ["esi-nixos" "esi-laptop" "esi-phone"] {
          user = "root";
        };
      };
    };
  };
}
