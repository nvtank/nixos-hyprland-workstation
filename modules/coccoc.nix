{ pkgs, ... }:

let
  coccoc = pkgs.stdenv.mkDerivation rec {
    pname = "coccoc-browser-stable";
    version = "152.0.7977.124-1";

    src = pkgs.fetchurl {
      url = "https://browser-linux.coccoc.com/deb/pool/main/coccoc-browser-stable_${version}_amd64.deb";
      sha256 = "0bqi4q87wwzxhsbgmdv56x5j4v3z72q3a8sysr7s9hbfyxavrrzv";
    };

    nativeBuildInputs = with pkgs; [
      autoPatchelfHook
      dpkg
      wrapGAppsHook
    ];

    buildInputs = with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      cairo
      cups
      dbus
      expat
      fontconfig
      freetype
      gdk-pixbuf
      glib
      gtk3
      libappindicator-gtk3
      libdrm
      libnotify
      libpulseaudio
      libuuid
      libxkbcommon
      mesa
      nspr
      nss
      pango
      systemd
      xdg-utils
      xorg.libX11
      xorg.libXScrnSaver
      xorg.libXcomposite
      xorg.libXcursor
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXi
      xorg.libXrandr
      xorg.libXrender
      xorg.libXtst
      xorg.libxcb
      xorg.libxshmfence
    ];

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb -x $src .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r opt/coccoc $out/coccoc
      cp -r usr/share $out/share

      # Create wrapper script
      mkdir -p $out/bin
      cat > $out/bin/coccoc-browser << 'EOF'
      #!${pkgs.bash}/bin/bash
      exec $out/coccoc/coccoc-browser "$@"
      EOF
      chmod +x $out/bin/coccoc-browser

      # Symlink
      ln -s $out/bin/coccoc-browser $out/bin/coccoc

      # Fix desktop file if exists
      if [ -f $out/share/applications/coccoc-browser.desktop ]; then
        substituteInPlace $out/share/applications/coccoc-browser.desktop \
          --replace /opt/coccoc/coccoc-browser $out/bin/coccoc-browser \
          --replace /opt/coccoc/ $out/coccoc/
      fi

      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Cốc Cốc Browser - Vietnamese web browser based on Chromium";
      homepage = "https://coccoc.com";
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
      maintainers = [ ];
    };
  };
in
{
  environment.systemPackages = [ coccoc ];
  nixpkgs.config.allowUnfree = true;
}
