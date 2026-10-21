{ config, lib, pkgs, ... }:

{
  # ── Weekly NixOS Auto-Upgrade — Mondays 04:00 AM (Parité media & nginx) ────────

  system.autoUpgrade = {
    enable             = true;
    flake              = "github:leonpwd/nixos-rpi#${config.networking.hostName}";
    flags              = [
      "--no-write-lock-file"
    ];
    dates              = "Mon 04:00";
    randomizedDelaySec = "30min";
    persistent         = true;
    allowReboot        = true;
    rebootWindow = {
      lower = "04:00";
      upper = "06:00";
    };
  };

  # ── fcksws (Hono/Bun QR code service on port 3000) ───────────────────────────
  services.fcksws = {
    enable = true;
    port = 3000;
  };

  # ── notifynotes (Campus Inseec note scraper) ───────────────────────────────────
  services.notifynotes = {
    enable = true;
    environmentFile = config.sops.templates."notifynotes.env".path;
  };
}
