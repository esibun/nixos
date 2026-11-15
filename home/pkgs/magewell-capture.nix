{
  copyDesktopItems,
  dpkg,
  fetchurl,
  makeDesktopItem,
  makeWrapper,
  pkgs,
  polkit,
  stdenv,
  unzip,
  writeScript,
  xhost
}:

let
  pname = "magewell-usb-capture-utility";
  version = "3.0.5.48315";
  prefix = "3_deb_48315";

  # ugly workaround because the utility requires root; this isn't portable at all
  runAsRoot = writeScript "usbcaptureutility" ''
    ${xhost}/bin/xhost +si:localuser:root
    /run/wrappers/bin/pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY OUT/bin/.usbcaptureutility-wrapped
    ${xhost}/bin/xhost -si:localuser:root
  '';
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://www.magewell.com/files/tools/USBCaptureUtility${prefix}.zip";
    hash = "sha256-YzxLRnov0NgfzYQKKeErA53naxucdbaWG+0p/0MVDnQ=";
  };

  nativeBuildInputs = [ copyDesktopItems dpkg makeWrapper unzip ];
  buildInputs = [ polkit xhost ];

  desktopItems = [
    (makeDesktopItem {
      name = "Magewell USB Capture Utility";
      desktopName = "Magewell USB Capture Utility";
      exec = "usbcaptureutility";
      icon = "usbcaptureutility";
    })
  ];

  unpackPhase = ''
    unzip -j $src USBCaptureUtility${prefix}/usbcaptureutility_${version}Internal.deb -d .
    dpkg-deb -x ./usbcaptureutility_${version}Internal.deb .
    rm ./usbcaptureutility_${version}Internal.deb
  '';

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share/icons

    install ./usr/local/bin/* $out/bin
    cp -r ./usr/share/icons/* $out/share/icons
    mv $out/bin/usbcaptureutility $out/bin/.usbcaptureutility-wrapped
    substitute ${runAsRoot} $out/bin/usbcaptureutility \
      --replace-fail 'OUT' "$out"
    chmod +x $out/bin/usbcaptureutility

    runHook postInstall
  '';
}
