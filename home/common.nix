{pkgs, ...}:

{
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
      any-nix-shell
      unzip
    ];
    stateVersion = "23.11";
  };
}
