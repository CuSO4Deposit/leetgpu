{
  description = "Nix flake that setup CUDA devshell";

  nixConfig = {
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          system = system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
          };
        };
      in {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            cudaPackages.cudatoolkit
            linuxPackages.nvidia_x11
            ncurses5
          ];
          shellHook = with pkgs; ''
            export CUDA_PATH=${cudatoolkit}
            # export LD_LIBRARY_PATH=/usr/lib/wsl/lib:${linuxPackages.nvidia_x11}/lib:${ncurses5}/lib
            export EXTRA_LDFLAGS="-L/lib -L${linuxPackages.nvidia_x11}/lib"
            export EXTRA_CCFLAGS="-I/usr/include"
            alias nvcc='nvcc --cudadevrt none --cudart shared'
          '';
        };
    });
}
