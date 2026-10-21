# Justfile — Raspberry Pi 3B (Colmena & SOPS)

default:
    @just --list

# ── Colmena Deployment ─────────────────────────────────────────────────────────

# Apply configuration to Raspberry Pi
apply:
    nix run nixpkgs#colmena -- apply

# Dry-run activation
dry:
    nix run nixpkgs#colmena -- apply dry-activate

# Test configuration without setting boot default
test-colmena:
    nix run nixpkgs#colmena -- apply test
