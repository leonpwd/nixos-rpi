{ config, lib, pkgs, ... }:

{
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;

    appendHttpConfig = ''
      include ${config.sops.templates."nginx-vhosts.conf".path};
    '';
  };

  # Activation script runs as root with full privileges to prepare certs and directories
  system.activationScripts.nginxAcmeCerts = lib.stringAfter [ "users" ] ''
    mkdir -p /var/lib/acme/live /var/lib/acme/acme-challenge
    if [ ! -f /var/lib/acme/live/fullchain.pem ]; then
      ${pkgs.openssl.bin}/bin/openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /var/lib/acme/live/key.pem \
        -out /var/lib/acme/live/fullchain.pem \
        -subj "/CN=localhost"
    fi
    chown -R nginx:nginx /var/lib/acme
    chmod 750 /var/lib/acme/live /var/lib/acme/acme-challenge
  '';

  # ACME Certificate Management via Lego (Reading domains and email from SOPS)
  systemd.services.acme-renew = {
    description = "Obtain and renew ACME TLS certificates via Lego";
    after = [ "network.target" "nginx.service" ];
    wants = [ "nginx.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.lego pkgs.coreutils pkgs.systemd ];
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = config.sops.templates."acme.env".path;
      ExecStart = pkgs.writeShellScript "lego-run" ''
        set -euo pipefail
        mkdir -p /var/lib/acme/acme-challenge /var/lib/acme/live

        # Request or renew certificate using HTTP-01 challenge against Nginx webroot
        lego --path /var/lib/acme \
          --email "$ACME_EMAIL" \
          --http --http.webroot /var/lib/acme/acme-challenge \
          --domains "$DOMAIN" \
          --domains "$DOMAIN_ALIAS" \
          --accept-tos run || lego --path /var/lib/acme \
          --email "$ACME_EMAIL" \
          --http --http.webroot /var/lib/acme/acme-challenge \
          --domains "$DOMAIN" \
          --domains "$DOMAIN_ALIAS" \
          --days 30 renew || true

        # Install certs into the live directory
        if [ -f "/var/lib/acme/certificates/$DOMAIN.crt" ]; then
          cp "/var/lib/acme/certificates/$DOMAIN.crt" /var/lib/acme/live/fullchain.pem
          cp "/var/lib/acme/certificates/$DOMAIN.key" /var/lib/acme/live/key.pem
          chown -R nginx:nginx /var/lib/acme/live
          chmod 640 /var/lib/acme/live/*
          systemctl reload nginx
        fi
      '';
    };
  };

  # Daily timer to renew before expiry
  systemd.timers.acme-renew = {
    description = "Daily ACME certificate renewal check";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };
}
