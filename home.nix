{ config, pkgs, herdr, hunk, ... }:

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
    k = "kubectl";
    tree = "eza --tree --git-ignore";
    ns = "cd $HOME/nix-config && sudo nixos-rebuild switch --flake .#kennethl";
    t = "task";
  };

  dotfiles = "${config.home.homeDirectory}/dotfiles";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  configs = {
    ghostty = "ghostty";
    nvim = "nvim";
    opencode = "opencode";
    tmux = "tmux";
    tmuxinator = "tmuxinator";
    zed = "zed";
    task = "task";
    herdr = "herdr";
  };
in
{
  xdg.configFile = builtins.mapAttrs
    (name: subpath: {
      source = create_symlink "${dotfiles}/${subpath}";
      recursive = true;
    })
    configs;

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
    };
    "org/gnome/desktop/wm/keybindings" = {
      switch-to-workspace-1 = ["<Super>1"];
      switch-to-workspace-2 = ["<Super>2"];
      switch-to-workspace-3 = ["<Super>3"];
      switch-to-workspace-4 = ["<Super>4"];
      switch-to-workspace-5 = ["<Super>5"];
      switch-to-workspace-6 = ["<Super>z"];
      switch-to-workspace-7 = ["<Super>x"];
      switch-to-workspace-8 = ["<Super>c"];
      switch-to-workspace-9 = ["<Super>v"];
      switch-to-workspace-10 = ["<Super>g"];
      move-to-workspace-1 = ["<Super><Shift>1"];
      move-to-workspace-2 = ["<Super><Shift>2"];
      move-to-workspace-3 = ["<Super><Shift>3"];
      move-to-workspace-4 = ["<Super><Shift>4"];
      move-to-workspace-5 = ["<Super><Shift>5"];
      move-to-workspace-6 = ["<Super><Shift>z"];
      move-to-workspace-7 = ["<Super><Shift>x"];
      move-to-workspace-8 = ["<Super><Shift>c"];
      move-to-workspace-9 = ["<Super><Shift>v"];
      move-to-workspace-10 = ["<Super><Shift>g"];
      toggle-maximized = ["<Super>f"];
      close = ["<Super><Shift>q"];
    };
    "org/gnome/mutter" = {
      dynamic-workspaces = false;
    };
    "org/gnome/desktop/wm/preferences" = {
      num-workspaces = 10;
    };
    "org/gnome/shell/keybindings" = {
      toggle-overview = ["<Super>d"];
      toggle-message-tray = [];
      switch-to-application-1 = [];
      switch-to-application-2 = [];
      switch-to-application-3 = [];
      switch-to-application-4 = [];
      switch-to-application-5 = [];
      switch-to-application-6 = [];
      switch-to-application-7 = [];
      switch-to-application-8 = [];
      switch-to-application-9 = [];
    };
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Settings";
      command = "gnome-control-center";
      binding = "<Super>comma";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      name = "Ghostty";
      command = "ghostty";
      binding = "<Super>Return";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
      name = "Browser";
      command = "xdg-open https://";
      binding = "<Super>b";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
      name = "Files";
      command = "nautilus";
      binding = "<Super><Shift>Return";
    };
    "org/gnome/desktop/screensaver" = {
      lock-enabled = false;
    };
    "org/gnome/desktop/session" = {
      idle-delay = 0;
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
      bindkey -s '^t' 'tmux-sessionizer -t\n'
    '';
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true; # or enableBashIntegration
  };

  programs.borgmatic = {
    enable = true;
    backups."kennethl-ws" = {
      location = {
        sourceDirectories = [
          "${config.home.homeDirectory}/Documents"
          "${config.home.homeDirectory}/Pictures"
          "${config.home.homeDirectory}/Videos"
          "${config.home.homeDirectory}/Calibre Library"
          "${config.home.homeDirectory}/Music"
          "${config.home.homeDirectory}/Vaults"
        ];
        repositories = [
          {
            path = "/mnt/backup/borg-repositories/kennethl-ws";
            label = "local";
          }
        ];
        extraConfig = {
          exclude_patterns = [
            ".cache"
            ".local/share/Trash"
          ];
        };
      };
      storage = {
        encryptionPasscommand = "${pkgs.pass}/bin/pass backup/borg";
        extraConfig = {
          compression = "auto,zstd";
        };
      };
      retention = {
        keepDaily = 7;
        keepWeekly = 4;
        keepMonthly = 6;
      };
      consistency = {
        checks = [
          { name = "repository"; frequency = "2 weeks"; }
          { name = "archives"; frequency = "1 month"; }
        ];
      };
    };
  };

  programs.btop = {
    enable = true;
  
    settings = {
      vim_keys = true;
    };
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
  };

  home.packages = with pkgs; [
    lazygit
    thunar
    mdadm
    brave
    google-chrome
    btop
    obsidian
    opencode
    starship
    borgmatic
    pass
    gnupg
    pinentry-curses
    calibre
    go
    eza
    herdr.packages.${pkgs.system}.default
    hunk.packages.${pkgs.stdenv.hostPlatform.system}.default
    gh
    gnome-font-viewer
    dconf-editor
    dotnet-sdk_10
    nodejs
    tree-sitter
    roslyn-ls
    taskwarrior3
    kubectl
    kubernetes-helm
    k9s
    gitleaks
    tmuxinator
    jq
    zoxide
    just
    argocd
    borgbackup
    nautilus
    portfolio
    zed-editor
    vlc
  ];

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.config/tmux/bin"
    "$HOME/.config/herdr/bin"
  ];

  programs.starship = {
    enable = true;
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

  programs.atuin = {
    enable = true;
    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      sync_address = "https://api.atuin.sh";
      search_mode = "fuzzy";
    };
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

  systemd.user.services.k3s-cluster-backup = {
    Unit.Description = "Pull K3s Cluster backup from homeserver";

    Service = {
      Type = "oneshot";
      ExecStart = create_symlink "${config.home.homeDirectory}/Projects/personal/homeserver/k3s-backup/backup-cluster";
    };
  };

  systemd.user.timers.k3s-cluster-backup = {
    Unit.Description = "K3s cluster backup at 20:00";

    Timer = {
      OnCalendar = "*-*-* 20:00:00";
      RandomizedDelaySec = "2min";
      Persistent = true;
    };

    Install.WantedBy = [ "timers.target" ];
  };

  systemd.user.services.borgmatic = {
    Unit.Description = "Run borgmatic backup";

    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.borgmatic}/bin/borgmatic";
    };
  };

  systemd.user.timers.borgmatic = {
    Unit.Description = "Run borgmatic backup daily at 03:00";

    Timer = {
      OnCalendar = "*-*-* 03:00:00";
      RandomizedDelaySec = "30min";
      Persistent = true;
    };

    Install.WantedBy = [ "timers.target" ];
  };

  home.sessionVariables = {
    TERMINAL = "ghostty";
  };

  home.stateVersion = "26.05";
}
