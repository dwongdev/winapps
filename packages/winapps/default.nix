{
  stdenv,
  lib,
  fetchFromGitHub,
  makeWrapper,
  freerdp3,
  dialog,
  libnotify,
  netcat,
  iproute2,
  ...
}:
let
  rev = "885d02079a36aa9696de46440c5b29b95278f904";
  hash = "sha256-hkD1siuwlRNOnXpDETZEQlIb/j91hkCspAUl/m5BB6g=";
in
stdenv.mkDerivation rec {
  pname = "winapps";
  version = "0-unstable-2025-05-26";

  src = fetchFromGitHub {
    owner = "winapps-org";
    repo = "winapps";

    inherit rev hash;
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [
    freerdp3
    libnotify
    dialog
    netcat
    iproute2
  ];

  patches = [
    ./winapps.patch
    ./setup.patch
  ];

  postPatch = ''
    substituteAllInPlace bin/winapps
    substituteAllInPlace setup.sh
    patchShebangs install/inquirer.sh
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    mkdir -p $out/src

    cp -r ./ $out/src/

    install -m755 -D bin/winapps $out/bin/winapps
    install -m755 -D setup.sh $out/bin/winapps-setup

    for f in winapps-setup winapps; do
      wrapProgram $out/bin/$f \
        --set LIBVIRT_DEFAULT_URI "qemu:///system" \
        --prefix PATH : "${lib.makeBinPath buildInputs}"
    done

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://github.com/winapps-org/winapps";
    description = "Run Windows applications (including Microsoft 365 and Adobe Creative Cloud) on GNU/Linux with KDE, GNOME or XFCE, integrated seamlessly as if they were native to the OS. Wayland is currently unsupported.";
    mainProgram = "winapps";
    platforms = platforms.linux;
    license = licenses.agpl3Plus;
  };
}
