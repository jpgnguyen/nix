{
  user,
  homeDir,
  inputs,
  hostname,
  architecture,
}: {pkgs, ...}: {
  # Define home directory.
  users.users.${user}.home = homeDir;

  # Install system-wide packages.
  environment.systemPackages = [
    pkgs.neovim
    pkgs.alejandra
    pkgs.age
    pkgs.ssh-to-age
    pkgs.python313
  ];

  # Set default editor to neovim.
  environment.variables = {
    EDITOR = "nvim";
    SYSTEMD_EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Install homebrew casks for GUI apps.
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

  # Homebrew settings.
  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = user;
  };

  # Home Manager settings. Import home manager configuration from home.nix.
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${user} = import ./home.nix {inherit user homeDir inputs;};
    sharedModules = [
      inputs.sops-nix.homeManagerModules.sops
    ];
  };

  # Enable OpenSSH.
  services.openssh.enable = true;

  # Nix setup.
  nix.settings.experimental-features = "nix-command flakes";
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  system.stateVersion = 6;
  nixpkgs.hostPlatform = architecture;
}
