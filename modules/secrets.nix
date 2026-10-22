{ config, ... }:

{
  sops = {
    defaultSopsFile   = ../secrets/rpi.yaml;
    defaultSopsFormat = "yaml";
    age.sshKeyPaths   = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets."notifynotes/url"       = {};
    secrets."notifynotes/ntfy_url"  = {};
    secrets."notifynotes/ntfy_user" = {};
    secrets."notifynotes/ntfy_pass" = {};

    secrets."nginx/domain"       = {};
    secrets."nginx/domain_alias" = {};
    secrets."nginx/acme_email"   = {};

    templates."notifynotes.env".content = ''
      URL=${config.sops.placeholder."notifynotes/url"}
      NTFY_URL=${config.sops.placeholder."notifynotes/ntfy_url"}
      NTFY_AUTH=true
      NTFY_USER=${config.sops.placeholder."notifynotes/ntfy_user"}
      NTFY_PASS=${config.sops.placeholder."notifynotes/ntfy_pass"}
      TZ=Europe/Paris
    '';

    templates."nginx-vhosts.conf" = {
      content = ''
        server {
          listen 80;
          listen [::]:80;
          server_name ${config.sops.placeholder."nginx/domain"} ${config.sops.placeholder."nginx/domain_alias"};

          location /.well-known/acme-challenge/ {
            root /var/lib/acme/acme-challenge;
          }

          location / {
            return 301 https://$host$request_uri;
          }
        }

        server {
          listen 443 ssl default_server;
          listen [::]:443 ssl default_server;
          server_name ${config.sops.placeholder."nginx/domain"} ${config.sops.placeholder."nginx/domain_alias"};

          ssl_certificate /var/lib/acme/live/fullchain.pem;
          ssl_certificate_key /var/lib/acme/live/key.pem;

          add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

          # Block access to hidden files and directories (.env, .git, etc.)
          location ~ /\. {
            deny all;
            return 404;
          }

          location / {
            proxy_pass http://127.0.0.1:3000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          }
        }
      '';
      owner = "nginx";
      group = "nginx";
      mode = "0644";
    };

    templates."acme.env" = {
      content = ''
        DOMAIN=${config.sops.placeholder."nginx/domain"}
        DOMAIN_ALIAS=${config.sops.placeholder."nginx/domain_alias"}
        ACME_EMAIL=${config.sops.placeholder."nginx/acme_email"}
      '';
      owner = "root";
      group = "root";
      mode = "0600";
    };
  };
}
