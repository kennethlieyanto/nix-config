{ config, pkgs, ... }:

{
  boot.swraid = {
    enable = true;
    mdadmConf = ''
    ARRAY metadata=imsm UUID=ed52c932:3dc04989:ce96ef00:acb6561e devices=/dev/sdb,/dev/sdc
    ARRAY /dev/md/RAID1MIRROR container=ed52c932:3dc04989:ce96ef00:acb6561e member=0 UUID=4e85d156:500f04ca:119b91fa:13dcf2ea
    '';
  };

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = true;
      AllowUsers = ["kennethl"];
      UseDns = true;
      X11Forwarding = false;
      PermitRootLogin = "prohibit-password";
    };
  };
  services.fail2ban.enable = true;

  # Separate 1 TB HDD 
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/82efbdbb-ad71-4d99-8ec3-b1fb9ef2fc71";
    fsType = "ext4";
  };

  # 3TB RAID1MIRROR
  fileSystems."/mnt/backup" = {
    device = "/dev/disk/by-uuid/4c156b50-4366-440d-ad0e-f77cbb2412ca";
    fsType = "ext4";
  };

  imports = [ ./hardware-configuration.nix ];

  nixpkgs.config.packageOverrides = pkgs: {
    polybar = pkgs.polybar.override {
      i3Support = true;
    };
  };   

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "kennethl-ws"; # Define your hostname.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Jakarta";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  programs.zsh.enable = true;
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."kennethl" = {
    isNormalUser = true;
    description = "Kenneth Lieyanto";
    extraGroups = [ "networkmanager" "wheel" "video" "audio"];
    packages = with pkgs; [];
    shell = pkgs.zsh;

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN52WotGSFEXGAYpT1YVuk9BsUsX01rfofYkEMv5aTjn root@kennethl-asuslaptop"
    ];
  };

  programs.dconf.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     ghostty
     gnumake
     gcc
     psmisc
     fzf
     findutils
     vim
     wget
     git
     curl
     kitty
     firefox
     rofi
     polychromatic
     neovim
     ripgrep
     fd
     fzf
     tmux
     htop
     libreoffice-qt
     hunspell
     hunspellDicts.uk_UA
     hunspellDicts.id_ID
     unzip
     dnsutils
     pwgen
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };

  services.libinput.enable = true;
  
  services.libinput.mouse = {
    accelProfile = "flat";
    accelSpeed = "0";
  };

  services.xserver = {
    enable = true;
    videoDrivers = ["nvidia"];

    displayManager.lightdm.enable = true;

    screenSection = ''
      Option "metamodes" "DP-0: 1920x1080_165 +0+0"
    '';

    windowManager.i3 = {
       enable = true;
       extraPackages = with pkgs; [
         i3status
         i3lock
         dmenu
       ];
    };
  };


  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
  };

  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];
        settings = {
          main = {
            capslock = "leftmeta";
            leftalt = "layer(leftalt)";
          };
          "leftalt:A" = {
            h = "left";
            j = "down";
            k = "up";
            l = "right";
          };
          shift = {
            leftshift = "capslock";
            rightshift = "capslock";
          };
        };
      };
    };
  };

  hardware.openrazer = {
    enable = true;
    users = ["kennethl"];
  };

  programs.steam = {
    enable = true;
  };

  services.syncthing = {
    enable = true;
    user = "kennethl";
    dataDir = "/home/kennethl";
    configDir = "/home/kennethl/.config/syncthing";
    openDefaultPorts = true;
    guiPasswordFile = "/etc/syncthing-gui-password";
    settings = {
      gui.user = "kennethl";
      devices = {
        "kennethl-a35" = { id = "Y47XQJ5-V5WCQTX-N2MB5WS-Z6L6SGE-3KOKPCL-OCY5TJV-OIHFIB3-ZRSZJQI"; };
      };
      folders = {
        "Vaults/notes" = {
          path = "/home/kennethl/Vaults/notes";
          devices = [ "kennethl-a35" ];
          ignorePerms = false; # Enable file permission syncing
        };
      };
    };
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    inter
  ];

  environment.variables = {
    EDITOR = "nvim";
    MANPAGER = "nvim +Man!";
    VISUAL = "nvim";
  };

  services.udisks2 = {
    enable = true;
    mountOnMedia = true;
  };

  services.tailscale.enable = true;
  # Provide explicit upstream DNS so Tailscale MagicDNS always has
  # resolvers even if NetworkManager hasn't finished DHCP at boot
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    # Always allow traffic from your Tailscale network
    trustedInterfaces = [ config.services.tailscale.interfaceName ];
    # Allow the Tailscale UDP port through the firewall
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  # 2. Force tailscaled to use nftables (Critical for clean nftables-only systems)
  # This avoids the "iptables-compat" translation layer issues.
  systemd.services.tailscaled.serviceConfig.Environment = [ 
    "TS_DEBUG_FIREWALL_MODE=nftables" 
  ];

  # 3. Optimization: Prevent systemd from waiting for network online 
  # (Optional but recommended for faster boot with VPNs)
  systemd.network.wait-online.enable = false; 
  boot.initrd.systemd.network.wait-online.enable = false;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05";

}
