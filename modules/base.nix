{ config, lib, pkgs, inputs ? {}, ... }:

{
  # ── Base System ───────────────────────────────────────────────────────────────

  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "fr_FR.UTF-8";
  i18n.supportedLocales = [
    "fr_FR.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
  ];

  # MicroSD & RAM optimization for Raspberry Pi 3B (1GB RAM)
  zramSwap.enable = true;
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;
  };

  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "200M";
    cleanOnBoot = true;
  };
  systemd.coredump.enable = false;

  # Hardware Watchdog (BCM2837 automatic hardware recovery)
  systemd.settings.Manager = {
    RuntimeWatchdogSec    = "60s";
    RebootWatchdogSec     = "60s";
    KExecWatchdogSec      = "60s";
    DefaultTimeoutStopSec = "20s";
  };

  # ── Kernel & Sysctl Hardening / Optimizations ─────────────────────────────────

  boot.kernel.sysctl = {
    # Memory & Swap optimization for zram
    "vm.swappiness"                               = 180;

    # Kernel panic auto-reboot (headless resilience)
    "kernel.panic"                                = 10;
    "kernel.panic_on_oops"                        = 1;

    # TCP BBR congestion control & Fair Queueing
    "net.core.default_qdisc"                      = "fq";
    "net.ipv4.tcp_congestion_control"             = "bbr";
    "net.core.rmem_max"                           = 4194304;
    "net.core.wmem_max"                           = 4194304;

    # Filesystem protections
    "fs.protected_fifos"                          = 2;
    "fs.protected_regular"                        = 2;
    "fs.suid_dumpable"                            = 0;

    # Kernel hardening
    "dev.tty.ldisc_autoload"                      = 0;
    "kernel.kptr_restrict"                        = 2;
    "kernel.sysrq"                                = 0;
    "kernel.unprivileged_bpf_disabled"            = 1;
    "net.core.bpf_jit_harden"                     = 2;

    # Network anti-spoofing
    "net.ipv4.conf.all.log_martians"              = 1;
    "net.ipv4.conf.all.send_redirects"            = 0;
    "net.ipv4.conf.default.accept_redirects"      = 0;
    "net.ipv4.conf.default.log_martians"          = 1;
    "net.ipv6.conf.all.accept_redirects"          = 0;
    "net.ipv6.conf.default.accept_redirects"      = 0;
  };

  # ── Networking & Security ──────────────────────────────────────────────────────

  networking.hostName = "rpi";
  networking.useDHCP = lib.mkDefault true;

  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
    "2606:4700:4700::1111"
  ];

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];
    allowedUDPPorts = [ 5353 ]; # mDNS / Avahi
  };

  # mDNS service discovery (ssh leon@rpi.local)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      workstation = true;
    };
  };

  # Lightweight security (< 10MB RAM)
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      "127.0.0.1/8"
      "192.168.1.0/24"
      "10.0.0.0/8"
      "100.64.0.0/10"
    ];
    jails.nginx-botsearch = ''
      enabled  = true
      port     = http,https
      filter   = nginx-botsearch
      logpath  = /var/log/nginx/access.log
      backend  = auto
      maxretry = 2
    '';
  };

  # ── Users & SSH ────────────────────────────────────────────────────────────────

  users.mutableUsers = false;

  users.users.leon = {
    isNormalUser = true;
    extraGroups  = [ "wheel" ];
    shell        = pkgs.zsh;
    hashedPassword = "!";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKe2HveHRaZq27KLAgI8aa9rOI37xxFBfNOjgYI4Ph/ leon@rpi"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICe9/bK3E3xGB2AyMAZ8cpzi8AAWzFmeAUEPbSasCmDb root@nixos"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILw0xxAKSAbc5PMZncFMBUF7aNxqJAXRaClQgtLq+KOG lego@server"
    ];
  };

  users.users.root = {
    hashedPassword = "!";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKe2HveHRaZq27KLAgI8aa9rOI37xxFBfNOjgYI4Ph/ leon@rpi"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICe9/bK3E3xGB2AyMAZ8cpzi8AAWzFmeAUEPbSasCmDb root@nixos"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILw0xxAKSAbc5PMZncFMBUF7aNxqJAXRaClQgtLq+KOG lego@server"
    ];
  };

  security.sudo = {
    enable = true;
    execWheelOnly = true;
    wheelNeedsPassword = false;
    extraConfig = ''
      Defaults env_reset
      Defaults env_keep += "LANG LANGUAGE LINGUAS LC_* _XKB_CHARSET"
      Defaults timestamp_timeout=5
    '';
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication       = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin              = "no";
      AllowUsers                   = [ "leon" ];
      MaxAuthTries                 = 3;
      LoginGraceTime               = 20;
      ClientAliveInterval          = 300;
      ClientAliveCountMax          = 2;
      X11Forwarding                = false;
      PrintMotd                    = false;
      PrintLastLog                 = false;
    };
  };

  # ── Shell — Zsh + Powerlevel10k + Fastfetch (Parité media) ─────────────────────

  environment.shells = [ pkgs.zsh ];

  system.activationScripts.leonZshrc = lib.stringAfter [ "users" ] ''
    if [ ! -f /home/leon/.zshrc ]; then
      install -o leon -g users -m 644 /dev/null /home/leon/.zshrc
    fi
  '';

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    shellInit = ''
      if [[ "$TERM" == "xterm-ghostty" ]]; then export TERM=xterm-256color; fi
    '';

    promptInit = ''
      typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    '';

    interactiveShellInit = ''
      [[ ! -f /etc/p10k.zsh ]] || source /etc/p10k.zsh
      source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down
      alias ls='ls --color=auto'
      alias ll='ls -alF --color=auto'
      alias la='ls -A --color=auto'
      fastfetch --config /etc/fastfetch/config.jsonc
    '';
  };

  environment.etc."p10k.zsh".source               = ./etc/p10k;
  environment.etc."fastfetch/config.jsonc".source = ./etc/fastfetch.jsonc;

  system.activationScripts.serverJustfile = lib.stringAfter [ "users" ] ''
    install -m 644 ${./etc/server.just} /Justfile
  '';

  # ── Logging (Journald en RAM volatile pour préserver la MicroSD) ───────────────

  services.journald.extraConfig = ''
    Storage=volatile
    RuntimeMaxUse=50M
    RuntimeMaxFileSize=10M
  '';

  # Logrotate pour les journaux d'accès Nginx
  services.logrotate = {
    enable = true;
    settings.nginx = {
      files = "/var/log/nginx/*.log";
      frequency = "daily";
      rotate = 7;
      compress = true;
      delaycompress = true;
      postrotate = "[ ! -f /run/nginx/nginx.pid ] || kill -USR1 $(cat /run/nginx/nginx.pid)";
    };
  };

  # ── Nix Package Manager Hardening ──────────────────────────────────────────────

  systemd.services.nix-daemon.serviceConfig.Nice = 10;

  nix.channel.enable = false;

  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  nix.nixPath = [ "nixpkgs=flake:nixpkgs" ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "leon" ];
    auto-optimise-store = true;
    cores = 2;
    max-jobs = 1;
    substituters = [
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  nix.gc = {
    automatic = true;
    dates     = "weekly";
    options   = "--delete-older-than 14d";
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    fastfetch
    just
    tree
    btop
    ncdu
    jq
    bind.dnsutils
    lsof
    curl
  ];

  system.stateVersion = "26.05";
}
