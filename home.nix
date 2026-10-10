{
  config,
  pkgs,
  herdr,
  hunk,
  tw-gnome,
  ...
}:

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
    ns = "cd $HOME/nix-config && nix flake update tw-gnome && sudo nixos-rebuild switch --flake .#kennethl";
    t = "task";
    tt = "taskwarrior-tui";
  };

  dotfiles = "${config.home.homeDirectory}/dotfiles";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  rider = pkgs.callPackage ./pkgs/rider-fhs.nix { };
  taskwarrior-extension = pkgs.callPackage ./pkgs/tw-gnome.nix {
    src = tw-gnome;
  };

  resticAlertTo = "kennethlieyanto99@gmail.com";
  resticAlertFrom = "restic-notify@kennethlieyanto.com";
  resticAlertApiKeyFile = "${config.home.homeDirectory}/.config/restic-notify/api-key";
  resticWrapper = "${config.home.profileDirectory}/bin/restic-kennethl-ws";

  resticNotify = pkgs.writeShellApplication {
    name = "notify-restic";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      jq
    ];
    text = ''
            api_key_file="''${RESTIC_NOTIFY_API_KEY_FILE:-${resticAlertApiKeyFile}}"
            to="${resticAlertTo}"
            from="Restic Backup <${resticAlertFrom}>"
            restic="${resticWrapper}"
            mode="''${1:-}"

            if [ ! -r "$api_key_file" ]; then
              echo "notify-restic: cannot read API key file: $api_key_file" >&2
              exit 1
            fi

            send() {
              jq -n --arg from "$from" --arg to "$to" --arg subject "$1" --arg text "$2" \
                '{from:$from,to:[$to],subject:$subject,text:$text}' |
                curl --fail-with-body -sS -X POST "https://api.resend.com/emails" \
                  -H "Authorization: Bearer $(cat "$api_key_file")" \
                  -H "Content-Type: application/json" \
                  --data-binary @-
            }

            case "$mode" in
              backup-success)
                host="$(uname -n)"
                if snap="$( "$restic" snapshots --latest 1 --json --no-lock 2>/dev/null )"; then
                  short_id="$(printf '%s' "$snap" | jq -r '.[0].short_id // "-"')"
                  snap_time="$(printf '%s' "$snap" | jq -r '.[0].time // "-"')"
                  files_new="$(printf '%s' "$snap" | jq -r '.[0].summary.files_new // "-"')"
                  files_changed="$(printf '%s' "$snap" | jq -r '.[0].summary.files_changed // "-"')"
                  files_unmodified="$(printf '%s' "$snap" | jq -r '.[0].summary.files_unmodified // "-"')"
                  data_added="$(printf '%s' "$snap" | jq -r '.[0].summary.data_added // 0' | numfmt --to=iec)"
                  total="$(printf '%s' "$snap" | jq -r '.[0].summary.total_bytes_processed // 0' | numfmt --to=iec)"
                  body="restic backup succeeded on $host at $(date -Is).

      snapshot:           $short_id ($snap_time)
      files new/changed:  $files_new / $files_changed
      files unmodified:   $files_unmodified
      data added:         $data_added
      bytes processed:    $total"
                else
                  body="restic backup succeeded on $host at $(date -Is).
      (could not read snapshot details)"
                fi
                send "[$host] restic backup OK" "$body"
                ;;
              stale-check)
                host="$(uname -n)"
                state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/restic-notify"
                alert_file="$state_dir/last-stale-alert"
                threshold=604800
                remind=259200
                now="$(date +%s)"
                mkdir -p "$state_dir"

                recently_alerted() {
                  [ -f "$alert_file" ] && [ $(( now - $(cat "$alert_file") )) -lt "$remind" ]
                }

                if ! snap="$( "$restic" snapshots --latest 1 --json --no-lock 2>/dev/null )"; then
                  if ! recently_alerted; then
                    printf '%s' "$now" > "$alert_file"
                    send "[$host] restic: repository unreadable" \
                      "Could not read the restic repository at $(date -Is). Check that /mnt/backup is mounted."
                  fi
                  exit 0
                fi

                latest="$(printf '%s' "$snap" | jq -r '.[0].time // empty')"
                if [ -z "$latest" ]; then
                  if ! recently_alerted; then
                    printf '%s' "$now" > "$alert_file"
                    send "[$host] restic: no snapshots found" \
                      "The repository contains no snapshots."
                  fi
                  exit 0
                fi

                age=$(( now - $(date -d "$latest" +%s) ))
                if [ "$age" -le "$threshold" ]; then
                  rm -f "$alert_file"
                  exit 0
                fi

                if ! recently_alerted; then
                  printf '%s' "$now" > "$alert_file"
                  send "[$host] restic: no backup in $(( age / 86400 )) days" \
                    "Newest snapshot is from $latest ($(( age / 86400 )) days ago)."
                fi
                ;;
              *)
                echo "usage: notify-restic {backup-success|stale-check}" >&2
                exit 2
                ;;
            esac
    '';
  };

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
  xdg.configFile = builtins.mapAttrs (name: subpath: {
    source = create_symlink "${dotfiles}/${subpath}";
    recursive = true;
  }) configs;

  xdg.desktopEntries.rider = {
    name = "Rider";
    genericName = ".NET IDE from JetBrains";
    comment = "JetBrains Rider is a .NET IDE based on the IntelliJ platform and ReSharper.";
    exec = "rider";
    icon = "rider";
    categories = [ "Development" ];
    settings.StartupWMClass = "jetbrains-rider";
  };

  dconf.enable = true;
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
    };
    "org/gnome/desktop/wm/keybindings" = {
      switch-to-workspace-1 = [ "<Super>1" ];
      switch-to-workspace-2 = [ "<Super>2" ];
      switch-to-workspace-3 = [ "<Super>3" ];
      switch-to-workspace-4 = [ "<Super>4" ];
      switch-to-workspace-5 = [ "<Super>5" ];
      switch-to-workspace-6 = [ "<Super>z" ];
      switch-to-workspace-7 = [ "<Super>x" ];
      switch-to-workspace-8 = [ "<Super>c" ];
      switch-to-workspace-9 = [ "<Super>v" ];
      switch-to-workspace-10 = [ "<Super>g" ];
      move-to-workspace-1 = [ "<Super><Shift>1" ];
      move-to-workspace-2 = [ "<Super><Shift>2" ];
      move-to-workspace-3 = [ "<Super><Shift>3" ];
      move-to-workspace-4 = [ "<Super><Shift>4" ];
      move-to-workspace-5 = [ "<Super><Shift>5" ];
      move-to-workspace-6 = [ "<Super><Shift>z" ];
      move-to-workspace-7 = [ "<Super><Shift>x" ];
      move-to-workspace-8 = [ "<Super><Shift>c" ];
      move-to-workspace-9 = [ "<Super><Shift>v" ];
      move-to-workspace-10 = [ "<Super><Shift>g" ];
      toggle-maximized = [ "<Super>f" ];
      close = [ "<Super><Shift>q" ];
    };
    "org/gnome/mutter" = {
      dynamic-workspaces = false;
    };
    "org/gnome/desktop/wm/preferences" = {
      num-workspaces = 10;
    };
    "org/gnome/shell/keybindings" = {
      toggle-overview = [ "<Super>d" ];
      toggle-message-tray = [ ];
      switch-to-application-1 = [ ];
      switch-to-application-2 = [ ];
      switch-to-application-3 = [ ];
      switch-to-application-4 = [ ];
      switch-to-application-5 = [ ];
      switch-to-application-6 = [ ];
      switch-to-application-7 = [ ];
      switch-to-application-8 = [ ];
      switch-to-application-9 = [ ];
    };
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/"
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
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4" = {
      name = "Toggle Handy Transcription";
      command = "handy --toggle-transcription";
      binding = "XF86Launch5";
    };
    "org/gnome/desktop/screensaver" = {
      lock-enabled = false;
    };
  };

  programs.gnome-shell = {
    enable = true;
    extensions = [
      { package = pkgs.gnomeExtensions.appindicator; }
      { package = pkgs.gnomeExtensions.stopwatch; }
      { package = taskwarrior-extension; }
    ];
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
      bindkey -s '^f' 'herdr-sessionizer\n'
    '';
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true; # or enableBashIntegration
  };

  services.restic.enable = true;

  services.restic.backups.kennethl-ws = {
    repository = "/mnt/backup/restic-repositories/kennethl-ws";
    initialize = true;

    paths = [
      "${config.home.homeDirectory}/Documents"
      "${config.home.homeDirectory}/Pictures"
      "${config.home.homeDirectory}/Videos"
      "${config.home.homeDirectory}/Calibre Library"
      "${config.home.homeDirectory}/Music"
      "${config.home.homeDirectory}/Vaults"
      "${config.home.homeDirectory}/.ssh"
    ];

    exclude = [
      "**/.cache"
      "**/.local/share/Trash"
    ];

    passwordFile = "${config.home.homeDirectory}/.config/restic/password";

    extraBackupArgs = [
      "--compression"
      "max"
    ];
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];

    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      RandomizedDelaySec = "30min";
      Persistent = true;
    };
  };

  systemd.user.services.restic-backups-kennethl-ws.Service.ExecStartPost = [
    "-${resticNotify}/bin/notify-restic backup-success"
  ];

  systemd.user.services.restic-stale-check = {
    Unit.Description = "Alert if there has been no restic backup for over a week";

    Service = {
      Type = "oneshot";
      ExecStart = "${resticNotify}/bin/notify-restic stale-check";
    };
  };

  systemd.user.timers.restic-stale-check = {
    Unit.Description = "Daily restic staleness check";

    Timer = {
      OnCalendar = "*-*-* 09:00:00";
      Persistent = true;
    };

    Install.WantedBy = [ "timers.target" ];
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

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
  };

  home.packages = with pkgs; [
    handy
    lazygit
    thunar
    mdadm
    brave
    google-chrome
    btop
    obsidian
    opencode
    starship
    pass
    gnupg
    pinentry-curses
    calibre
    go
    cargo
    rustc
    clippy
    rustfmt
    rust-analyzer
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
    wev
    # safeeyes
    stretchly
    powershell
    rider
    bun
    netcoredbg
    nixd
    nixfmt # the one used by neovim support only single file
    nixfmt-tree # for project formatting
    prettierd
    esphome
    esphome-device-builder
    lazydocker
    taskwarrior-tui
    google-cloud-sdk
    restic
    bws
    wtype # needed by handy for dictation / voice typing
    dotool # needed by handy for dictation / voice typing
    sqlite
    dbeaver-bin
    gjs # for developing gnome extensions
    glib # for developing gnome extensions
    glib.dev
    gtk4 # for developing gnome extensions
    libadwaita # for developing gnome extensions
    exercism
    rustlings
  ];

  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhsWithPackages (
      ps: with ps; [
        dotnet-sdk_10
      ]
    );
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.config/tmux/bin"
    "$HOME/.config/herdr/bin"
    "$HOME/.dotnet/tools"
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

  systemd.user.services.restic-check-kennethl-ws = {
    Unit.Description = "Weekly restic data integrity check";

    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.profileDirectory}/bin/restic-kennethl-ws check --read-data-subset=5%";
    };
  };

  systemd.user.timers.restic-check-kennethl-ws = {
    Unit.Description = "Weekly restic data check";

    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
    };

    Install.WantedBy = [ "timers.target" ];
  };

  home.sessionVariables = {
    TERMINAL = "ghostty";
    DOTNET_ROOT = "${pkgs.dotnet-sdk_10}/share/dotnet/";
    RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
  };

  home.stateVersion = "26.05";
}
