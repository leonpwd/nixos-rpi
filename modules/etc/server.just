# server.just — Commandes utiles sur le Raspberry Pi 3B NixOS

default:
    @just --list

# ── NixOS ──────────────────────────────────────────────────────────────────────

# Lister les générations NixOS
generations:
    nix-env -p /nix/var/nix/profiles/system --list-generations

# Rollback vers la génération précédente
rollback:
    sudo nixos-rebuild switch --rollback

# Nettoyage manuel : supprime les générations de plus de 14 jours + GC
gc:
    sudo nix-collect-garbage --delete-older-than 14d

# Supprimer toutes les anciennes générations NixOS
berserk:
    sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations old

# Prochains déclenchements des timers systemd
timers:
    systemctl list-timers --no-pager

# ── Services Natifs (fcksws, notifynotes, nginx, fail2ban) ─────────────────────

# Statut des services
ps:
    systemctl status fcksws notifynotes nginx fail2ban --lines=2

# Logs d'un service (ex: just logs fcksws ou just logs notifynotes)
logs service:
    journalctl -u {{ service }}.service -n 200 -f --no-pager

# Redémarrer un service (ex: just restart fcksws)
restart service:
    sudo systemctl restart {{ service }}.service

# Renouveler les certificats TLS maintenant
cert-renew:
    sudo systemctl start acme-renew.service
    journalctl -u acme-renew.service -n 50 --no-pager

# Afficher l'état du système Fastfetch
info:
    fastfetch --config /etc/fastfetch/config.jsonc
