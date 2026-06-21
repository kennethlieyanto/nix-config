{ pkgs, ... }:

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
    ns= "sudo nixos-rebuild switch --flake $HOME/nix-config#kennethl";
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
    initContent = ''
      bindkey -s '^f' 'tmux-sessionizer\n'
    '';
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true; # or enableBashIntegration
  };

  programs.ghostty = {
    enable = true;
  
    settings = {
      font-size = 13;
  
      theme = "Ayu";
  
      keybind = [
        "ctrl+shift+%=new_split:right"
        "alt+shift+'=new_split:down"
        "ctrl+shift+x=close_surface"
  
        "shift+left=goto_split:left"
        "shift+down=goto_split:down"
        "shift+up=goto_split:up"
        "shift+right=goto_split:right"
  
        "ctrl+shift+p=toggle_command_palette"
      ];
  
      window-decoration = false;
    };
  };

  programs.btop = {
    enable = true;
  
    settings = {
      vim_keys = true;
    };
  };

  programs.tmux = {
    enable = true;
  
    terminal = "tmux-256color";
    escapeTime = 10;
    mouse = true;
    baseIndex = 1;
    keyMode = "vi";
    prefix = "C-a";
  
    extraConfig = ''
      set -ag terminal-overrides ",xterm-256color:RGB"
      set-option -g renumber-windows on
  
      set -g status-style bg=#0B0E14,fg=#BFBDB6
      set -g status-left ""
      set -g status-right-length 100
      set -g status-right "#[bg=#0B0E14,fg=#39BAE6]▏ [#(basename #{pane_current_path})] #(~/local/bin/task_polybar.sh)"
  
      set -g window-status-format "#[bg=#0B0E14,fg=#565B66]  #I: #W  "
      set -g window-status-current-format "#[bg=#FF8F40,fg=#0B0E14,bold]  #I: #W  "
      set -g window-status-style bg=#0B0E14,fg=#565B66
      set -g window-status-current-style bg=#FF8F40,fg=#0B0E14,bold
      set -g window-status-activity-style bg=#0B0E14,fg=#FF8F40
      set -g window-status-separator ""
  
      set -g pane-border-style bg=default,fg=#565B66
      set -g pane-active-border-style bg=default,fg=#39BAE6
  
      set -g message-style bg=#0B0E14,fg=#E6B450,bold
      set -g message-command-style bg=#0B0E14,fg=#E6B450,bold
  
      set -g mode-style bg=#1B3A5B,fg=#BFBDB6
  
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux.conf reloaded."
  
      bind ^ last-window
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
  
      bind -r C-h resize-pane -L 5
      bind -r C-j resize-pane -D 5
      bind -r C-k resize-pane -U 5
      bind -r C-l resize-pane -R 5
  
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "wl-copy && wl-paste -n | wl-copy -p"
      bind-key -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe "wl-copy"
  
      bind-key p run "wl-paste -n | tmux load-buffer - ; tmux paste-buffer"
  
      bind C new-window -c '#{pane_current_path}'
  
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
  
      bind-key -r < swap-window -t -1 \; select-window -t -1
      bind-key -r > swap-window -t +1 \; select-window -t +1
  
      set -g clock-mode-colour "#39BAE6"
    '';
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
    gh
    gnome-font-viewer
    # gsettings-desktop-schemas
    dotnet-sdk_10
    nodejs
    tree-sitter
    roslyn-ls
  ];

  home.sessionPath = [
    "$HOME/.local/bin"
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

  home.stateVersion = "26.05";
}
