{
  description = "Example nix-darwin system flake";

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
    alejandra = {
      url = "github:kamadorueda/alejandra/3.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:mic92/sops-nix";
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
    configuration = {pkgs, ...}: {
      imports = [inputs.sops-nix.darwinModules.sops];

      environment.systemPackages = [
        pkgs.neovim
        pkgs.alejandra
        pkgs.age
        pkgs.ssh-to-age
        pkgs.sops
      ];

      environment = {
        variables = {
          EDITOR = "neovim";
          SYSTEMD_EDITOR = "neovim";
          VISUAL = "neovim";
        };
      };

      users.users."joshnguyen" = {
        home = "/Users/joshnguyen";
      };

      homebrew = {
        enable = true;
        casks = [
          "nordvpn"
          "plex-media-server"
          "plex"
          "obsidian"
          "google-chrome"
          "visual-studio-code"
          "docker"
        ];
        onActivation.cleanup = "zap";
      };

      services = {
        openssh.enable = true;
      };

      sops = {
        defaultSopsFile = ./secrets.yaml;
        defaultSopsFormat = "yaml";
        secrets.example-key = { };
        age.keyFile = "/Users/joshnguyen/.config/sops/age/keys.txt";
        secrets."github" = {
          owner = "joshnguyen";
        };
      };

      nix.settings.experimental-features = "nix-command flakes";

      system.configurationRevision = self.rev or self.dirtyRev or null;
      system.stateVersion = 6;

      nixpkgs.hostPlatform = "aarch64-darwin";
    };

    homeConfiguration = {pkgs, ...}: {
      home.stateVersion = "24.05";
      home.packages = [
        pkgs.starship
      ];
      home.username = "joshnguyen";
      home.homeDirectory = "/Users/joshnguyen";

      programs = {
        home-manager.enable = true;
        ssh = {
          enable = true;
          extraConfig = ''
            Host github.com
            	AddKeysToAgent yes
            	IdentityFile ~/.ssh/github
          '';
        };
        zsh = {
          enable = true;
          autosuggestion.enable = true;
          enableCompletion = true;
          syntaxHighlighting.enable = true;
          shellAliases = {
            dr = "darwin-rebuild switch --flake ~/nix#Joshs-Mac-mini";
          };
        };
        git = {
          enable = true;
          userEmail = "joshuapgnguyen98@gmail.com";
          userName = "jpgnguyen";
        };
        starship = {
          enable = true;
        };
      };
    };
  in {
    darwinConfigurations."Joshs-Mac-mini" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = "joshnguyen";
          };
        }
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users."joshnguyen" = homeConfiguration;
        }
      ];
    };
  };
}
