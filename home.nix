{ config, pkgs, herdr, ... }:

let
  commonAliases = {
    rebuild = "sudo nixos-rebuild switch";
    o = "xdg-open";
    ls = "ls --color=auto";
    la = "ls -a";
    ll = "ls -al";
    sudo = "sudo ";
    lzg = "lazygit";
    lzd = "lazydocker";
    oc = "opencode";
    d = "docker";
    j = "just";
    jc = "just --choose";
    g = "git";
    tf = "terraform";
    cz = "chezmoi";
    k = "kubectl";
    tree = "eza --tree --git-ignore";
    ns = "cd $HOME/nix-config && sudo nixos-rebuild switch --flake .#kennethl";
    t = "task";
  };

  dotfiles = "${config.home.homeDirectory}/dotfiles";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  configs = {
    ghostty = "ghostty";
    i3 = "i3";
    nvim = "nvim";
    opencode = "opencode";
    polybar = "polybar";
    rofi = "rofi";
    tmux = "tmux";
    tmuxinator = "tmuxinator";
    zed = "zed";
    task = "task";
  };
in
{
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  programs.git = {
    enable = true;
  
    settings = {
      user = {
        name = "Kenneth Manuel Lieyanto";
        email = "kennethlieyanto99@gmail.com";
      };
  
      init.defaultBranch = "main";
      pull.rebase = true;
      core.editor = "nvim";
    };
  };

  programs.bash = {
    enable = true;
    shellAliases = commonAliases;
  };

  programs.zsh = {
    enable = true;
    shellAliases = commonAliases;
    defaultKeymap = "emacs";
    initContent = ''
      bindkey -s '^f' 'tmux-sessionizer\n'
    '';
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true; # or enableBashIntegration
  };

  programs.btop = {
    enable = true;
  
    settings = {
      vim_keys = true;
    };
  };

  home.packages = with pkgs; [
    chezmoi
    lazygit
    zoxide
    thunar
    dunst
    pavucontrol
    lxappearance
    mdadm
    brave
    google-chrome
    btop
    obsidian
    opencode
    starship
    borgbackup
    calibre
    go
    eza
    herdr.packages.${pkgs.system}.default
    gh
    gnome-font-viewer
    # gsettings-desktop-schemas
    dotnet-sdk_10
    nodejs
    tree-sitter
    roslyn-ls
    xclip
    taskwarrior3
    kubectl
    kubernetes-helm
    k9s
    gitleaks
    tmuxinator
    jq
  ];

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.config/tmux/bin"
  ];

  services.dunst = {
    enable = true;
  };

  programs.starship = {
    enable = true;
  };

  services.polybar = {
    enable = true;

    script = ''
      # kill old bars (important on reload)
      killall -q polybar

      # wait until it exits
      while pgrep -x polybar >/dev/null; do sleep 0.2; done

      # start bar (main monitor)
      polybar main &
    '';
  };

  programs.obsidian.cli.enable = true;

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
    ];
  };

  systemd.user.services.task-sync = {
    Unit.Description = "Taskwarrior sync";

    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.taskwarrior3}/bin/task sync";
    };
  };

  systemd.user.timers.task-sync = {
    Unit.Description = "Run task sync every 10 minutes";
  
    Timer = {
      OnBootSec = "0";
      OnUnitActiveSec = "10m";
    };
  
    Install.WantedBy = [ "timers.target" ];
  };

  xdg.configFile = builtins.mapAttrs
    (name: subpath: {
      source = create_symlink "${dotfiles}/${subpath}";
      recursive = true;
    })
    configs;

  home.stateVersion = "26.05";
}
