{pkgs, inputs, ...}:

{
  home.packages = with pkgs; [
    unstable.looking-glass-client
  ];
}
