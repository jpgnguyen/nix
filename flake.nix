{
  description = "Josh's MacOS nix-darwin flake.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Alejandra using for formatting .nix files.
    alejandra = {
      url = "github:kamadorueda/alejandra/3.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # sops-nix used for encrypting secrets.
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nix-darwin,
    nixpkgs,
    nix-homebrew,
    home-manager,
    alejandra,
    sops-nix,
  }: let
    user = "joshnguyen";
    homeDir = "/Users/${user}";
    architecture = "aarch64-darwin";
    hostname = "Joshs-Mac-mini";

    configuration = import ./darwin.nix {inherit user homeDir inputs hostname architecture;};
  in {
    darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew
        home-manager.darwinModules.home-manager
      ];
    };
  };
}
