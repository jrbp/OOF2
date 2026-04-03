{
  description = "OOF2: Object Oriented for Finite Elements 2D version.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    oofcanvas = {
      # url = "github://usnistgov/oofcanvas.git"; # what it shoud be after repo is public
      # url = "git+file:///home/jrb26/git/oofcanvas?ref=nix"; # temporary hack for local repo
      url = "git+ssh://git@gitlab.nist.gov/john.bonini/oofcanvas.git?ref=nix"; # works as long as keys are setup
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    oofcanvas,
  }: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "arm64-apple-darwin"
      "x86_64-apple-darwin"
    ];
    eachSupportedSystem = nixpkgs.lib.genAttrs supportedSystems;
    pyDeps = pyextra: ps:
      with ps;
        [
          numpy
          scikit-image
          matplotlib
          pygobject3
        ]
        ++ pyextra;
  in {
    packages = eachSupportedSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      oofCanvasPkgs = oofcanvas.packages.${system};
      pythonEnv = pkgs.python3.withPackages (pyDeps [oofCanvasPkgs.oofCanvasPython]);
    in {
      default = self.packages.${system}.oof2;
      oof2 = pkgs.stdenv.mkDerivation {
        pname = "oof2";
        version = "2.4.0";
        src = ./.;
        nativeBuildInputs = with pkgs; [
          cmake
          swig
          pkg-config
          wrapGAppsHook3
        ];
        buildInputs = with pkgs; [
          blas
          lapack
          oofCanvasPkgs.oofCanvas
          pythonEnv
          python3Packages.pygobject3 # pkgconf needs to see this (not just python)
          ## Do we need the following here?
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
      oof2Python = let
        oof = self.packages.${system}.oof2;
      in
        pkgs.python3.pkgs.buildPythonPackage {
          pname = "oof2Python";
          inherit (oof) version;
          dontUnpack = true;
          format = "other";
          installPhase = ''
            mkdir -p $out/${pkgs.python3.sitePackages}
            for f in ${oof}/${pkgs.python3.sitePackages}/*; do
              ln -s "$f" $out/${pkgs.python3.sitePackages}/
            done
          '';
          propagatedBuildInputs = [oof];
        };
    });

    devShells = eachSupportedSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      oofpkgs = self.packages.${system} // oofcanvas.packages.${system};
    in {
      default = self.devShells.${system}.build;
      build = pkgs.mkShell {
        inputsFrom = [self.packages.${system}.default];
      };
      run = pkgs.mkShell {
        packages = [
          oofpkgs.oof2
          (pkgs.python3.withPackages (pyDeps (with oofpkgs; [
            oofCanvasPython
            oof2Python
          ])))
        ];
      };
    });

    apps = eachSupportedSystem (system: let
      oofpkgs = self.packages.${system};
    in {
      default = {
        type = "app";
        program = "${oofpkgs.default}/bin/oof2";
      };
    });
  };
}
