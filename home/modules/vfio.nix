{pkgs, inputs, ...}:

{
  home.packages = with pkgs; [
    looking-glass-client
  ];
}
