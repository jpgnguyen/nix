Nix darwin configuration. General structure:

 - Homebrew casks for GUI apps.
 - Home-manager for user and dotfiles.
 - Nix-sops for secret management.

Todo:
  - Separate files for home-manager and darwin configurations, and import into flake.
  - Install dbeaver
  - Configure starship
  - Use secrets.yaml to auth to github.
