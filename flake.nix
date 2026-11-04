{
  description = "Chronicle — cross-platform student planner (Flutter: Linux + Android)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate =
          pkg: builtins.elem (pkg.pname or pkg.name) [ "android-studio" ];
      };
      # System libs the Android emulator's qemu needs (NixOS has no /usr/lib).
      emulatorLibs = with pkgs; [
        libpng
        libGL
        alsa-lib
        pulseaudio
        nss
        nspr
        libxkbcommon
        libxkbfile
        libSM
        libICE
        libbsd
        dbus
        libdrm
        expat
        util-linux
        zlib
        libx11
        libxcomposite
        libxcursor
        libxdamage
        libxext
        libxfixes
        libxi
        libxrandr
        libxrender
        libxtst
        libxcb
        libxcb-util
        xcb-util-cursor
        libxcb-image
        libxcb-keysyms
        libxcb-render-util
        libxcb-wm
      ];
    in
    {
      # Default shell: Flutter + Linux desktop build toolchain.
      # Enter with: nix develop
      devShells.${system}.default = pkgs.mkShell {
        name = "chronicle-flutter";

        buildInputs = with pkgs; [
          flutter
          temurin-bin-17 # JDK for Gradle (debug APK builds)
          android-studio # Android Studio IDE + AVD emulator (on-device screenshots)
          # Linux desktop embedder build deps.
          gtk3 # provides gtk+-3.0.pc for pkg-config (flutter embedder links GTK3)
          sqlite # libsqlite3.so for drift; NixOS has no global /usr/lib
          cmake
          ninja
          pkg-config
          git
        ] ++ emulatorLibs;

        shellHook = ''
          export SQLITE_LIB="${pkgs.sqlite.out}/lib"
          export EMU_LIBS="${pkgs.lib.makeLibraryPath emulatorLibs}"
          export LD_LIBRARY_PATH="$EMU_LIBS:$SQLITE_LIB''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
          export JAVA_HOME="${pkgs.temurin-bin-17}"
          echo "Chronicle dev shell ready."
        '';
      };

      # Android builds need the SDK composition + JDK (several GB).
      # Added when we reach the Android milestone:
      #   nix develop .#android
      # devShells.${system}.android = ...
    };
}
