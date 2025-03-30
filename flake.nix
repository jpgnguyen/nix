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

    configuration = {pkgs, ...}: {
      users.users.${user}.home = homeDir;

      # Install system wide packages.
      environment.systemPackages = [
        pkgs.neovim
        pkgs.alejandra
        pkgs.age
        pkgs.ssh-to-age
      ];

      # Set default editor to neovim.
      environment = {
        variables = {
          EDITOR = "nvim";
          SYSTEMD_EDITOR = "nvim";
          VISUAL = "nvim";
        };
      };

      # Install homebrew casks, currently using these for GUI apps.
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
          "dbeaver-community"
        ];
        onActivation.cleanup = "zap";
      };

      # Enable OpenSSH as off by default on MacOS.
      services = {
        openssh.enable = true;
      };

      # Nix setup.
      nix.settings.experimental-features = "nix-command flakes";
      system.configurationRevision = self.rev or self.dirtyRev or null;
      system.stateVersion = 6;
      nixpkgs.hostPlatform = architecture;
    };

    homeConfiguration = {
      pkgs,
      config,
      ...
    }: {
      imports = [
        inputs.sops-nix.homeManagerModules.sops
      ];

      home.stateVersion = "24.05";
      home.packages = [
        pkgs.starship
        pkgs.sops
      ];

      home.username = user;
      home.homeDirectory = homeDir;

      home.sessionVariables = {
        SOPS_AGE_KEY_FILE = "${homeDir}/.config/sops/age/keys.txt";
      };

      sops = {
        age.keyFile = "${homeDir}/.config/sops/age/keys.txt";
        defaultSopsFile = ./secrets.yaml;
        secrets."github_username" = {};
        secrets."github_email" = {};
      };

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
            dr = "darwin-rebuild switch --flake ~/nix#${hostname}";
          };
        };
        git = {
          enable = true;
          userName = config.sops.secrets."github_username".path;
          userEmail = config.sops.secrets."github_email".path;
        };
        starship = {
          enable = true;
        };
      };
    };
  in {
    darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = user;
          };
        }
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${user} = homeConfiguration;
          home-manager.sharedModules = [
            sops-nix.homeManagerModules.sops
          ];
        }
      ];
    };
  };
}
