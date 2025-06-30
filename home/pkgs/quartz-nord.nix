{
  stdenv,
  fetchFromGitHub,
  lib,
}:

stdenv.mkDerivation rec {
  pname = "Quartz-Nord";
  version = "0.7";

  src = fetchFromGitHub {
    owner = "darkomarko42";
    repo = pname;
    rev = "717d145d596e2e05ce237a6c91f05affc3e193ad";
    sha256 = "sha256-Kvrj9oj/IX98wclOTPxIiW4CCfPtJ3fVXRBqowmguRM=";
  };

  installPhase = ''
    mkdir -p $out/share/themes
    cp -r "$src/Quartz Nord" $out/share/themes/
    cp -r "$src/Quartz Dark Nord" $out/share/themes/
  '';

  meta = with lib; {
    homepage = "https://github.com/darkomarko42/Quartz-Nord";
    license = licenses.gpl3Only;
    maintainers = [ ];
  };
}
