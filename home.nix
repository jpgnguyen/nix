{
  user,
  homeDir,
  inputs,
}: {
  pkgs,
  config,
  ...
}: {
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  # Home manager settings.
  home.stateVersion = "24.05";
  home.username = user;
  home.homeDirectory = homeDir;

  # Install packages for user only.
  home.packages = [
    pkgs.starship
    pkgs.sops
  ];

  # Enable sops commands on zsh shell by providing age key pair location.
  home.sessionVariables = {
    SOPS_AGE_KEY_FILE = "${homeDir}/.config/sops/age/keys.txt";
  };

  # Sops-nix secret management. Age key pair defined and used to access secrets.yaml throught sops.
  sops = {
    age.keyFile = "${homeDir}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    secrets."github_username" = {};
    secrets."github_email" = {};
  };

  programs = {
    # Enable home manager.
    home-manager.enable = true;

    # .ssh dotfile configuration.
    ssh = {
      enable = true;
      extraConfig = ''
        Host github.com
          AddKeysToAgent yes
          IdentityFile ~/.ssh/github
      '';
    };

    # .zshrc dotfile configuration.
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        dr = "darwin-rebuild switch --flake ~/nix#${user}";
      };
    };

    # Starship zsh prompt configuration.
    starship.enable = true;

    # .config/git/config configuration.
    git = {
      enable = true;
      userName = config.sops.secrets."github_username".path;
      userEmail = config.sops.secrets."github_email".path;
    };
  };
}
