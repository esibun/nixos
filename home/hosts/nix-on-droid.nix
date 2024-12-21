{pkgs, lib, ...}:

let dnshack = pkgs.callPackage (builtins.fetchTarball "https://github.com/ettom/dnshack/tarball/master") {};
in
{
  imports = [
    ../common.nix
  ];

  home = rec {
    homeDirectory = "/data/data/com.termux.nix/files/home";
    stateVersion = "24.05";
    username = "nix-on-droid";

    # taken from nix-on-droid#120
    activation = {
      copyFont = let
          font_src = "${pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; }}/share/fonts/truetype/NerdFonts/FiraCodeNerdFontMono-Regular.ttf";
          font_dst = "${homeDirectory}/.termux/font.ttf";
        in lib.hm.dag.entryAfter ["writeBoundary"] ''
          ( test ! -e "${font_dst}" || test $(sha1sum "${font_src}"|cut -d' ' -f1 ) != $(sha1sum "${font_dst}" |cut -d' ' -f1)) && $DRY_RUN_CMD install $VERBOSE_ARG -D "${font_src}" "${font_dst}"
      '';
    };
  };

  programs.bash.initExtra = lib.mkBefore ''
    export DNSHACK_RESOLVER_CMD="${dnshack}/bin/dnshackresolver"
    export LD_PRELOAD="${dnshack}/lib/libdnshackbridge.so"
  '';
}
