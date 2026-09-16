{
  description = "Chronicle — cross-platform student planner (Flutter: Linux + Android)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      # Default shell: Flutter + Linux desktop build toolchain.
      # Enter with: nix develop
      devShells.${system}.default = pkgs.mkShell {
        name = "chronicle-flutter";

        buildInputs = with pkgs; [
          flutter
          # Linux desktop embedder build deps.
          gtk3 # provides gtk+-3.0.pc for pkg-config (flutter embedder links GTK3)
          cmake
          ninja
          pkg-config
          git
        ];

        shellHook = ''
          echo "Chronicle dev shell ready."
        '';
      };

      # Android builds need the SDK composition + JDK (several GB).
      # Added when we reach the Android milestone:
      #   nix develop .#android
      # devShells.${system}.android = ...
    };
}
