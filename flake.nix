{
  description = "OOF2: Object Oriented for Finite Elements 2D version.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    oofcanvas = {
      #url = "gitlab:john.bonini/oofcanvas/nix?host=gitlab.nist.gov"; # private so http doesn't work
      #url = "git+file:///home/jrb26/git/oofcanvas?ref=nix"; # temporary hack
      url = "git+ssh://git@gitlab.nist.gov/john.bonini/oofcanvas.git?ref=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    oofcanvas,
  }: let
    supportedSystems = ["x86_64-linux" "aarch64-linux" "i686-linux"];
    eachSupportedSystem = nixpkgs.lib.genAttrs supportedSystems;
  in {
    packages = eachSupportedSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      oofCanvasPkgs = oofcanvas.packages.${system};
      pythonEnv = pkgs.python3.withPackages (ps:
        with ps; [
          numpy
          scikit-image
          matplotlib
          pygobject3
          oofCanvasPkgs.oofCanvasPython
        ]);
    in {
      default = self.packages.${system}.oof2;
      oof2 = pkgs.stdenv.mkDerivation {
        pname = "oof2";
        version = "2.4.0";

        src = ./.;

        nativeBuildInputs = with pkgs; [
          cmake
          pkg-config
          wrapGAppsHook3
        ];
        buildInputs = with pkgs; [
          openblas
          oofCanvasPkgs.oofCanvas
          pythonEnv
          python3Packages.pygobject3 # pkgconf needs to see this (not just python)
          swig
          # Do we need the following here?
          # gtk3
          # cairomm
          # pango
          # gobject-introspection
          # glib
        ];

        meta = with pkgs.lib; {
          description = "OOF2: Object Oriented for Finite Elements 2D version.";
          license = licenses.nistSoftware;
          platforms = platforms.linux;
        };
      };
    });
    devShells = eachSupportedSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in
      pkgs.mkShell {
        inputsFrom = [ self.packages.${system}.default ];
      });
  };
}
