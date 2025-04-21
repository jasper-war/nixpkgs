{ lib, stdenv, fetchurl, makeWrapper, autoPatchelfHook
, gtk3, nss, nspr, systemd, at-spi2-atk, libdrm, mesa, libxkbcommon, libX11
, libXcomposite, libXdamage, libXext, libXfixes, libXrandr, expat, cups
, dbus, libXScrnSaver, libXtst, alsa-lib, libuuid, libsecret, musl, glibc
}:

let
  muslPackages = import <nixpkgs> { 
    localSystem = { 
      config = "x86_64-unknown-linux-musl";
    };
  };
in

stdenv.mkDerivation rec {
  pname = "tabby";
  version = "1.0.223";

  src = fetchurl {
    url = "https://github.com/Eugeny/tabby/releases/download/v${version}/tabby-${version}-linux-x64.tar.gz";
    sha256 = "sha256-m8Ocwd+ORVe7oaPxoGPAdt9C9wVB9m87VEf4X5xzyZA=";
  };

  nativeBuildInputs = [ makeWrapper autoPatchelfHook ];

  buildInputs = [
    gtk3 nss nspr systemd at-spi2-atk libdrm mesa libxkbcommon libX11
    libXcomposite libXdamage libXext libXfixes libXrandr expat cups
    dbus libXScrnSaver libXtst alsa-lib libuuid libsecret
    muslPackages.musl
  ];

  sourceRoot = "./tabby-${version}-linux-x64";

  dontBuild = true;
  
  # Fix permissions before autoPatchelfHook runs
  preFixup = ''
    chmod +x tabby chrome-sandbox chrome_crashpad_handler
  '';
  
  installPhase = ''
    echo $(ls .)
    mkdir -p $out/bin
    mkdir -p $out/opt/tabby
    
    cp -r ./* $out/opt/tabby/
    
    # Make sure the executable is actually executable
    chmod +x $out/opt/tabby/tabby
    chmod +x $out/opt/tabby/chrome-sandbox
    chmod +x $out/opt/tabby/chrome_crashpad_handler
    
    # Create wrapper
    makeWrapper $out/opt/tabby/tabby $out/bin/tabby \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs}
    
    # Create desktop file
    mkdir -p $out/share/applications
    cat > $out/share/applications/tabby.desktop << EOF
    [Desktop Entry]
    Name=Tabby
    Comment=A terminal for a more modern age
    Exec=$out/bin/tabby
    Icon=$out/opt/tabby/resources/app.asar.unpacked/icons/tabby.png
    Terminal=false
    Type=Application
    Categories=Development;System;TerminalEmulator;
    EOF
  '';

  meta = with lib; {
    description = "A terminal for a more modern age";
    homepage = "https://tabby.sh/";
    license = licenses.mit;
    maintainers = with maintainers; [ /* your name here */ ];
    platforms = [ "x86_64-linux" ];
  };
}
