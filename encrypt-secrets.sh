#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
OUT_FILE="$SCRIPT_DIR/secrets/rpi.yaml"

[ -f "$ENV_FILE" ] || { echo "❌ Fichier d'environnement .env introuvable"; exit 1; }

set -a; source "$ENV_FILE"; set +a

mkdir -p "$SCRIPT_DIR/secrets"
touch "$OUT_FILE" && chmod 600 "$OUT_FILE"

cat > "$OUT_FILE" << EOF
notifynotes:
  url: "${INSEEC_URL:-}"
  ntfy_url: "${NTFY_URL:-}"
  ntfy_user: "${NTFY_USER:-}"
  ntfy_pass: "${NTFY_PASS:-}"
nginx:
  domain: "${DOMAIN:-}"
  domain_alias: "${DOMAIN_ALIAS:-}"
  acme_email: "${ACME_EMAIL:-}"
EOF

cd "$SCRIPT_DIR"
sops --encrypt --in-place "$OUT_FILE"
chmod 644 "$OUT_FILE"

echo "✅ secrets/rpi.yaml chiffré avec succès."
